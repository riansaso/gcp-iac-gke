output "vpc_name" {
  value       = module.networking.vpc_name
  description = "VPC network name"
}

output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE cluster name"
}

output "gke_cluster_endpoint" {
  value       = module.gke.cluster_endpoint
  description = "GKE cluster endpoint (private)"
  sensitive   = true
}

output "gke_workload_identity_pool" {
  value       = module.gke.workload_identity_pool
  description = "Workload Identity pool for GKE"
}

output "postgres_connection_name" {
  value       = module.postgres.instance_connection_name
  description = "PostgreSQL Cloud SQL connection string"
}

output "postgres_private_ip" {
  value       = module.postgres.private_ip_address
  description = "PostgreSQL private IP address"
}

output "redis_host" {
  value       = module.redis.redis_host
  description = "Redis instance host"
}

output "redis_port" {
  value       = module.redis.redis_port
  description = "Redis instance port"
}

output "docker_repo_url" {
  value       = module.artifact_registry.docker_repository_url
  description = "Docker/OCI Artifact Registry URL"
}

output "helm_repo_url" {
  value       = module.artifact_registry.helm_repository_url
  description = "Helm Artifact Registry OCI URL"
}

output "external_secrets_sa_email" {
  value       = module.iam.external_secrets_sa_email
  description = "External Secrets Operator service account email"
}

output "flux_system_sa_email" {
  value       = module.iam.flux_system_sa_email
  description = "Flux GitOps service account email"
}

output "app_sa_email" {
  value       = module.iam.app_sa_email
  description = "Application service account email"
}

output "cluster_region" {
  value       = var.region
  description = "GCP region of the cluster"
}

output "project_id" {
  value       = var.project_id
  description = "GCP Project ID"
}
