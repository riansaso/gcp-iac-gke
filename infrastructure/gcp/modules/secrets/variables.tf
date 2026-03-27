variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for secret replication"
}

variable "create_example_secret" {
  type        = bool
  description = "Create example secret for reference"
  default     = true
}

variable "example_secret_name" {
  type        = string
  description = "Name of the example secret"
  default     = "app-database-url"

  validation {
    condition     = can(regex("^[a-z0-9-_]+$", var.example_secret_name))
    error_message = "Secret name must contain only lowercase letters, numbers, hyphens, and underscores."
  }
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
