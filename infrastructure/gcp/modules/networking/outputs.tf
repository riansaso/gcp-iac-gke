output "vpc_name" {
  value       = google_compute_network.primary.name
  description = "Name of the VPC network"
}

output "vpc_id" {
  value       = google_compute_network.primary.id
  description = "Self-link of the VPC network"
}

output "vpc_self_link" {
  value       = google_compute_network.primary.self_link
  description = "Self-link of the VPC network (for cross-references)"
}

output "gke_nodes_subnet_name" {
  value       = google_compute_subnetwork.gke_nodes.name
  description = "Name of the GKE nodes subnet"
}

output "gke_nodes_subnet_id" {
  value       = google_compute_subnetwork.gke_nodes.id
  description = "ID of the GKE nodes subnet"
}

output "gke_nodes_subnet_self_link" {
  value       = google_compute_subnetwork.gke_nodes.self_link
  description = "Self-link of the GKE nodes subnet"
}

output "pods_secondary_range" {
  value = {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }
  description = "Secondary IP range for pods"
}

output "services_secondary_range" {
  value = {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
  description = "Secondary IP range for services"
}

output "cloud_router_name" {
  value       = google_compute_router.nat_router.name
  description = "Name of the Cloud Router"
}

output "nat_gateway_ips" {
  value       = google_compute_router_nat.nat.nat_ips
  description = "NAT gateway external IPs (empty until traffic flows)"
}
