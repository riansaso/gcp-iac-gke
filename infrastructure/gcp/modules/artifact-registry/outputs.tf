output "docker_repository_name" {
  value       = var.create_docker_repo ? google_artifact_registry_repository.docker[0].name : null
  description = "Name of the Docker repository"
}

output "docker_repository_url" {
  value       = var.create_docker_repo ? "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker[0].repository_id}" : null
  description = "URL of the Docker repository"
}

output "helm_repository_name" {
  value       = var.create_helm_repo ? google_artifact_registry_repository.helm[0].name : null
  description = "Name of the Helm repository"
}

output "helm_repository_url" {
  value       = var.create_helm_repo ? "oci://${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.helm[0].repository_id}" : null
  description = "OCI URL of the Helm repository"
}
