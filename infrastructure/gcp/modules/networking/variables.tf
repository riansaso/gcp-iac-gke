variable "project_id" {
  type        = string
  description = "GCP Project ID"

  validation {
    condition     = can(regex("^[a-z0-9-]{6,30}$", var.project_id))
    error_message = "Project ID must be 6-30 characters, lowercase letters, numbers, and hyphens only."
  }
}

variable "region" {
  type        = string
  description = "GCP region for deployment"
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., us-central1)."
  }
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC network"
  default     = "gcp-vpc-primary"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.vpc_name))
    error_message = "VPC name must be 1-63 characters, lowercase letters, numbers, and hyphens only."
  }
}

variable "primary_cidr" {
  type        = string
  description = "CIDR block for primary VPC subnet"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.primary_cidr, 0))
    error_message = "Primary CIDR must be a valid CIDR notation (e.g., 10.0.0.0/16)."
  }
}

variable "gke_nodes_cidr" {
  type        = string
  description = "CIDR block for GKE node subnet"
  default     = "10.1.0.0/20"

  validation {
    condition     = can(cidrhost(var.gke_nodes_cidr, 0))
    error_message = "GKE nodes CIDR must be a valid CIDR notation."
  }
}

variable "pods_cidr" {
  type        = string
  description = "CIDR block for pod IP range (alias IP range)"
  default     = "10.64.0.0/14"

  validation {
    condition     = can(cidrhost(var.pods_cidr, 0))
    error_message = "Pods CIDR must be a valid CIDR notation."
  }
}

variable "services_cidr" {
  type        = string
  description = "CIDR block for service IP range (alias IP range)"
  default     = "10.68.0.0/14"

  validation {
    condition     = can(cidrhost(var.services_cidr, 0))
    error_message = "Services CIDR must be a valid CIDR notation."
  }
}

variable "enable_private_google_access" {
  type        = bool
  description = "Enable Private Google Access on subnets"
  default     = true
}

variable "enable_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs for network monitoring"
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
    project     = "gcp-iac-gke"
  }
}
