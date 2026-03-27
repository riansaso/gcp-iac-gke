terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ==========================================
# External Secrets Operator Service Account
# ==========================================

resource "google_service_account" "external_secrets" {
  count         = var.create_external_secrets_sa ? 1 : 0
  account_id    = "external-secrets-sa"
  display_name  = "Service account for External Secrets Operator"
  project       = var.project_id
  labels        = var.labels
}

# Allow ESO's Kubernetes SA to impersonate the GCP SA (Workload Identity Federation)
resource "google_service_account_iam_member" "external_secrets_workload_identity" {
  count              = var.create_external_secrets_sa ? 1 : 0
  service_account_id = google_service_account.external_secrets[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace_external_secrets}/external-secrets]"
}

# Grant ESO access to GCP Secret Manager
resource "google_project_iam_member" "external_secrets_secret_accessor" {
  count   = var.create_external_secrets_sa ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets[0].email}"
}

# ==========================================
# Flux GitOps Service Account
# ==========================================

resource "google_service_account" "flux_system" {
  count         = var.create_flux_sa ? 1 : 0
  account_id    = "flux-system-sa"
  display_name  = "Service account for Flux GitOps"
  project       = var.project_id
  labels        = var.labels
}

# Allow Flux's Kubernetes SA to impersonate the GCP SA
resource "google_service_account_iam_member" "flux_system_workload_identity" {
  count              = var.create_flux_sa ? 1 : 0
  service_account_id = google_service_account.flux_system[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace_flux_system}/flux-system]"
}

# Grant Flux access to Artifact Registry (for pulling Helm charts)
resource "google_project_iam_member" "flux_artifact_registry_reader" {
  count   = var.create_flux_sa ? 1 : 0
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.flux_system[0].email}"
}

# ==========================================
# Sample Application Service Account
# ==========================================

resource "google_service_account" "app_sa" {
  count         = var.create_app_sa ? 1 : 0
  account_id    = "demo-app-sa"
  display_name  = "Service account for demo application"
  project       = var.project_id
  labels        = var.labels
}

# Allow app's Kubernetes SA to impersonate the GCP SA
resource "google_service_account_iam_member" "app_sa_workload_identity" {
  count              = var.create_app_sa ? 1 : 0
  service_account_id = google_service_account.app_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace_applications}/demo-app]"
}

# Grant app access to Cloud SQL
resource "google_project_iam_member" "app_cloud_sql_client" {
  count   = var.create_app_sa ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.app_sa[0].email}"
}

# Grant app access to store credentials in Secret Manager
resource "google_project_iam_member" "app_secret_accessor" {
  count   = var.create_app_sa ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app_sa[0].email}"
}
