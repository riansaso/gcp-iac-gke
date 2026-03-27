variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the database"
}

variable "vpc_self_link" {
  type        = string
  description = "Self-link of the VPC network"
}

variable "database_instance_name" {
  type        = string
  description = "Name of the Cloud SQL instance"
  default     = "postgres-primary"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,43}$", var.database_instance_name))
    error_message = "Instance name must be 1-43 characters, lowercase letters, numbers, and hyphens."
  }
}

variable "database_version" {
  type        = string
  description = "PostgreSQL version"
  default     = "POSTGRES_15"

  validation {
    condition     = can(regex("^POSTGRES_[0-9]+$", var.database_version))
    error_message = "Database version must be in format POSTGRES_NN (e.g., POSTGRES_15)."
  }
}

variable "tier" {
  type        = string
  description = "Machine tier for Cloud SQL"
  default     = "db-f1-micro"

  validation {
    condition     = can(regex("^db-[a-z0-9]+-[a-z0-9]+$", var.tier))
    error_message = "Tier must be a valid Cloud SQL tier."
  }
}

variable "disk_size_gb" {
  type        = number
  description = "Initial disk size in GB"
  default     = 10

  validation {
    condition     = var.disk_size_gb >= 10 && var.disk_size_gb <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "backup_configuration_enabled" {
  type        = bool
  description = "Enable automated backups"
  default     = true
}

variable "backup_location" {
  type        = string
  description = "Location for backups (multi-region for production)"
  default     = "us"
}

variable "enable_iam_authentication" {
  type        = bool
  description = "Enable IAM database authentication"
  default     = true
}

variable "create_database" {
  type        = bool
  description = "Create a default database"
  default     = true
}

variable "database_name" {
  type        = string
  description = "Name of the database"
  default     = "application"

  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.database_name))
    error_message = "Database name must be 1-63 characters."
  }
}

variable "create_app_user" {
  type        = bool
  description = "Create an application user (IAM-authenticated)"
  default     = true
}

variable "app_user_email" {
  type        = string
  description = "Email of the application service account"
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
