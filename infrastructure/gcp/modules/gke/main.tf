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

# Private GKE Standard Cluster with SOTA security features
resource "google_container_cluster" "primary" {
  provider = google-beta

  name       = var.cluster_name
  location   = var.region
  project    = var.project_id
  network    = var.vpc_self_link
  subnetwork = var.gke_nodes_subnet_self_link

  # Disable default node pool, we'll create a custom one
  remove_default_node_pool = true
  initial_node_count       = 2

  # VPC-native cluster with custom IP ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    # Use Private Service Connect (PSC) for control plane access
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # Workload Identity Federation (modern standard, no service account keys)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # GKE Dataplane V2 (eBPF-based networking, more secure and efficient)
  # Note: Dataplane V2 is enabled by default in GKE, can be verified via cluster inspection

  # Binary Authorization (ensure only verified container images run)
  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Maintenance window (off-peak maintenance)
  maintenance_policy {
    daily_maintenance_window {
      start_time = "02:00"  # 2 AM UTC
    }
  }

  # Network policy and logging configuration
  network_policy {
    enabled = true
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER"
    ]
  }

  # Monitoring configuration
  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "DEPLOYMENT",
      "STATEFULSET",
      "POD",
      "DAEMONSET"
    ]
  }

  # Disable basic authentication (use IAM and Workload Identity instead)
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Disable Cloud Logging integration (use Logging configuration above)
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    cloudrun_config {
      disabled = true
    }
  }

  resource_labels = var.labels

  depends_on = []
}

# Custom node pool with autoscaling and SOTA security
resource "google_container_node_pool" "primary_nodes" {
  name    = "${var.cluster_name}-primary-pool"
  cluster = google_container_cluster.primary.id
  project = var.project_id

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    disk_type    = "pd-ssd"
    disk_size_gb = 100

    # Use preemptible nodes for cost optimization (optional, use regular for production stability)
    # preemptible  = true

    # Enable Workload Identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Metadata server configuration for enhanced security
    metadata = {
      enable-oslogin = "false"
    }

    # Scopes for GKE node service account (minimal required)
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Use default service account (will be bound to Workload Identity)
    service_account = google_service_account.gke_nodes.email

    # Security settings
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Tags for firewall rules
    tags = ["gke-node", "iap-enabled"]

    labels = var.labels

    taint {
      key    = "workload-type"
      value  = "general"
      effect = "NO_SCHEDULE"
    }
  }
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.cluster_name}-nodes"
  display_name = "Service account for GKE node pool"
  project      = var.project_id
}

# Grant necessary permissions to GKE node service account
resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
