variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "cluster_workload_identity_pool" {
  type        = string
  description = "Workload Identity pool for the cluster (e.g., project.svc.id.goog)"
}

variable "cluster_location" {
  type        = string
  description = "Location of the GKE cluster"
}

variable "create_external_secrets_sa" {
  type        = bool
  description = "Create service account for External Secrets Operator"
  default     = true
}

variable "create_flux_sa" {
  type        = bool
  description = "Create service account for Flux"
  default     = true
}

variable "create_app_sa" {
  type        = bool
  description = "Create sample application service account"
  default     = true
}

variable "namespace_external_secrets" {
  type        = string
  description = "Kubernetes namespace for External Secrets"
  default     = "external-secrets"
}

variable "namespace_flux_system" {
  type        = string
  description = "Kubernetes namespace for Flux"
  default     = "flux-system"
}

variable "namespace_applications" {
  type        = string
  description = "Kubernetes namespace for applications"
  default     = "applications"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
