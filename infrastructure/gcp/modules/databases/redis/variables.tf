variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for Redis instance"
}

variable "redis_instance_name" {
  type        = string
  description = "Name of the Redis instance"
  default     = "redis-primary"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.redis_instance_name))
    error_message = "Redis instance name must be 1-40 characters."
  }
}

variable "redis_version" {
  type        = string
  description = "Redis version"
  default     = "7.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.redis_version))
    error_message = "Redis version must be in format X.Y (e.g., 7.0)."
  }
}

variable "memory_size_gb" {
  type        = number
  description = "Memory size in GB"
  default     = 1

  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 300
    error_message = "Memory size must be between 1 and 300 GB."
  }
}

variable "tier" {
  type        = string
  description = "Service tier (STANDARD or PREMIUM)"
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "PREMIUM"], var.tier)
    error_message = "Tier must be STANDARD or PREMIUM."
  }
}

variable "vpc_network" {
  type        = string
  description = "VPC network name"
}

variable "authorized_network" {
  type        = string
  description = "Authorized network for Private Service Connection"
  default     = ""
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
