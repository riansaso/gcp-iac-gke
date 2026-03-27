output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Name of the GKE cluster"
}

output "cluster_id" {
  value       = google_container_cluster.primary.id
  description = "ID of the GKE cluster"
}

output "cluster_self_link" {
  value       = google_container_cluster.primary.self_link
  description = "Self-link of the GKE cluster"
}

output "cluster_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE cluster endpoint (private)"
  sensitive   = true
}

output "region" {
  value       = google_container_cluster.primary.location
  description = "GCP region of the cluster"
}

output "workload_identity_pool" {
  value       = "${var.project_id}.svc.id.goog"
  description = "Workload Identity pool for the cluster workspace"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}

output "gke_node_service_account_email" {
  value       = google_service_account.gke_nodes.email
  description = "Email of the GKE node service account"
}

output "gke_node_service_account_unique_id" {
  value       = google_service_account.gke_nodes.unique_id
  description = "Unique ID of the GKE node service account"
}
