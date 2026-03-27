terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# GCP Secret Manager for storing application secrets
# Secrets are encrypted at rest and accessed via IAM

# Example secret for demonstration
resource "google_secret_manager_secret" "example" {
  count      = var.create_example_secret ? 1 : 0
  secret_id  = var.example_secret_name
  project    = var.project_id
  labels     = var.labels

  replication {
    automatic = true
  }
}

# Placeholder secret version (in practice, use `gcloud secrets versions add` or Terraform data sources)
resource "google_secret_manager_secret_version" "example" {
  count              = var.create_example_secret ? 1 : 0
  secret             = google_secret_manager_secret.example[0].id
  secret_data        = "placeholder-value-replace-with-actual-secret"  # Change this!
  deletion_window    = 336  # 2 weeks retention
}

# Set up IAM policy for secret access (examples)
resource "google_secret_manager_secret_iam_member" "example_accessor" {
  count     = var.create_example_secret ? 1 : 0
  secret_id = google_secret_manager_secret.example[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}@cloudservices.gserviceaccount.com"
}
