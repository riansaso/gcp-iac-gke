output "example_secret_name" {
  value       = var.create_example_secret ? google_secret_manager_secret.example[0].id : null
  description = "Name of the example secret"
}

output "secret_manager_enabled" {
  value       = true
  description = "Flag indicating GCP Secret Manager is configured"
}
