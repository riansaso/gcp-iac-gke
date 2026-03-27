terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Docker/OCI repository for container images
resource "google_artifact_registry_repository" "docker" {
  count           = var.create_docker_repo ? 1 : 0
  location        = var.region
  repository_id   = var.docker_repo_name
  description     = "Docker/OCI container image repository"
  format          = "DOCKER"
  project         = var.project_id
  kms_key_name    = null  # Use Google-managed encryption
  labels          = var.labels
}

# Helm OCI repository for charts
resource "google_artifact_registry_repository" "helm" {
  count           = var.create_helm_repo ? 1 : 0
  location        = var.region
  repository_id   = var.helm_repo_name
  description     = "Helm chart repository (OCI format)"
  format          = "DOCKER"  # Helm v3 uses OCI format
  project         = var.project_id
  kms_key_name    = null
  labels          = var.labels
}

# Grant permissions for reading repositories
resource "google_artifact_registry_repository_iam_member" "docker_reader" {
  count       = var.create_docker_repo ? 1 : 0
  location    = google_artifact_registry_repository.docker[0].location
  repository  = google_artifact_registry_repository.docker[0].name
  role        = "roles/artifactregistry.reader"
  member      = "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com"
  project     = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "helm_reader" {
  count       = var.create_helm_repo ? 1 : 0
  location    = google_artifact_registry_repository.helm[0].location
  repository  = google_artifact_registry_repository.helm[0].name
  role        = "roles/artifactregistry.reader"
  member      = "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com"
  project     = var.project_id
}
