output "external_secrets_sa_email" {
  value       = var.create_external_secrets_sa ? google_service_account.external_secrets[0].email : null
  description = "Email of the External Secrets Operator service account"
}

output "flux_system_sa_email" {
  value       = var.create_flux_sa ? google_service_account.flux_system[0].email : null
  description = "Email of the Flux GitOps service account"
}

output "app_sa_email" {
  value       = var.create_app_sa ? google_service_account.app_sa[0].email : null
  description = "Email of the sample application service account"
}

output "workload_identity_setup_complete" {
  value       = true
  description = "Flag indicating Workload Identity Federation has been set up"
}
