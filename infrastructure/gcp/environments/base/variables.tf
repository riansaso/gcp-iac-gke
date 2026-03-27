variable "project_id" {
  type        = string
  description = "GCP Project ID"

  validation {
    condition     = can(regex("^[a-z0-9-]{6,30}$", var.project_id))
    error_message = "Project ID must be 6-30 characters, lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  type        = string
  description = "GCP region for infrastructure"
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+$", var.region))
    error_message = "Region must be a valid GCP region."
  }
}

variable "project_name" {
  type        = string
  description = "Short name for the project (used in resource naming)"
  default     = "gcp-iac"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "Project name must be 3-20 characters."
  }
}

# ==========================================
# Networking Variables
# ==========================================
variable "vpc_primary_cidr" {
  type        = string
  description = "CIDR block for primary VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_primary_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "gke_nodes_cidr" {
  type        = string
  description = "CIDR block for GKE node subnet"
  default     = "10.1.0.0/20"

  validation {
    condition     = can(cidrhost(var.gke_nodes_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "pods_cidr" {
  type        = string
  description = "CIDR block for pods (secondary IP range)"
  default     = "10.64.0.0/14"

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "services_cidr" {
  type        = string
  description = "CIDR block for services (secondary IP range)"
  default     = "10.68.0.0/14"

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# ==========================================
# GKE Variables
# ==========================================
variable "gke_min_nodes" {
  type        = number
  description = "Minimum number of GKE nodes"
  default     = 3

  validation {
    condition     = var.gke_min_nodes >= 1 && var.gke_min_nodes <= 1000
    error_message = "Must be between 1 and 1000."
  }
}

variable "gke_max_nodes" {
  type        = number
  description = "Maximum number of GKE nodes"
  default     = 10

  validation {
    condition     = var.gke_max_nodes >= 1 && var.gke_max_nodes <= 1000
    error_message = "Must be between 1 and 1000."
  }
}

variable "gke_machine_type" {
  type        = string
  description = "Machine type for GKE nodes"
  default     = "n2-standard-4"
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable Binary Authorization on GKE"
  default     = true
}

variable "enable_workload_identity" {
  type        = bool
  description = "Enable Workload Identity Federation"
  default     = true
}

variable "enable_gke_dataplane_v2" {
  type        = bool
  description = "Enable GKE Dataplane V2 networking"
  default     = true
}

# ==========================================
# PostgreSQL Variables
# ==========================================
variable "postgres_version" {
  type        = string
  description = "PostgreSQL version"
  default     = "POSTGRES_15"
}

variable "postgres_tier" {
  type        = string
  description = "Cloud SQL machine tier"
  default     = "db-f1-micro"
}

variable "postgres_disk_size_gb" {
  type        = number
  description = "PostgreSQL disk size in GB"
  default     = 10

  validation {
    condition     = var.postgres_disk_size_gb >= 10 && var.postgres_disk_size_gb <= 65536
    error_message = "Disk size must be between 10 and 65536 GB."
  }
}

variable "postgres_database_name" {
  type        = string
  description = "Default PostgreSQL database name"
  default     = "application"
}

# ==========================================
# Redis Variables
# ==========================================
variable "redis_version" {
  type        = string
  description = "Redis version"
  default     = "7.0"
}

variable "redis_memory_size_gb" {
  type        = number
  description = "Redis memory size in GB"
  default     = 1

  validation {
    condition     = var.redis_memory_size_gb >= 1 && var.redis_memory_size_gb <= 300
    error_message = "Memory size must be between 1 and 300 GB."
  }
}

variable "redis_tier" {
  type        = string
  description = "Redis service tier (BASIC or STANDARD_HA)"
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.redis_tier)
    error_message = "Must be BASIC or STANDARD_HA."
  }
}

# ==========================================
# Labels
# ==========================================
variable "labels" {
  type        = map(string)
  description = "Common labels for all resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
    project     = "gcp-iac-gke"
    created_at  = "2026-03-26"
  }
}
