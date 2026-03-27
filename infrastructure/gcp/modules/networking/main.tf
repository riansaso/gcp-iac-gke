terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Primary VPC Network
resource "google_compute_network" "primary" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Primary Subnet for GKE nodes
resource "google_compute_subnetwork" "gke_nodes" {
  name          = "${var.vpc_name}-nodes-${var.region}"
  project       = var.project_id
  network       = google_compute_network.primary.name
  region        = var.region
  ip_cidr_range = var.gke_nodes_cidr

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = var.enable_private_google_access

  depends_on = [google_compute_network.primary]
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-router-${var.region}"
  project = var.project_id
  region  = var.region
  network = google_compute_network.primary.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for egress from private cluster
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat-${var.region}"
  router                             = google_compute_router.nat_router.name
  region                             = google_compute_router.nat_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Allow internal VPC communication
resource "google_compute_firewall" "allow_internal" {
  name      = "${var.vpc_name}-allow-internal"
  project   = var.project_id
  network   = google_compute_network.primary.name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = [var.gke_nodes_cidr]

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
}

# IAP Firewall Rule - Allow Identity-Aware Proxy to connect
resource "google_compute_firewall" "allow_iap" {
  name      = "${var.vpc_name}-allow-iap"
  project   = var.project_id
  network   = google_compute_network.primary.name
  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["35.235.240.0/20"]  # Google Cloud IAP IP range

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]  # SSH and RDP
  }

  target_tags = ["iap-enabled"]
}

# Deny all egress by default (principle of least privilege)
resource "google_compute_firewall" "deny_all_egress" {
  name      = "${var.vpc_name}-deny-all-egress"
  project   = var.project_id
  network   = google_compute_network.primary.name
  direction = "EGRESS"
  priority  = 65534  # Lower priority than allow rules

  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }
}

# Allow egress to Google APIs and services (necessary for GKE)
resource "google_compute_firewall" "allow_google_apis" {
  name      = "${var.vpc_name}-allow-google-apis"
  project   = var.project_id
  network   = google_compute_network.primary.name
  direction = "EGRESS"
  priority  = 1000

  destination_ranges = ["199.36.0.0/10"]  # Google Private IP range

  allow {
    protocol = "tcp"
  }
}

# Allow DNS for private cluster
resource "google_compute_firewall" "allow_dns_egress" {
  name      = "${var.vpc_name}-allow-dns-egress"
  project   = var.project_id
  network   = google_compute_network.primary.name
  direction = "EGRESS"
  priority  = 1000

  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "udp"
    ports    = ["53"]
  }
}
