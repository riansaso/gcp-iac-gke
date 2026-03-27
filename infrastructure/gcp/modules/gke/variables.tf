variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for GKE cluster"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster"
  default     = "gke-primary-cluster"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,40}$", var.cluster_name))
    error_message = "Cluster name must be 1-40 characters, lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_self_link" {
  type        = string
  description = "Self-link of the VPC network"
}

variable "gke_nodes_subnet_self_link" {
  type        = string
  description = "Self-link of the GKE nodes subnet"
}

variable "pods_secondary_range_name" {
  type        = string
  description = "Name of the pods secondary IP range"
  default     = "pods"
}

variable "services_secondary_range_name" {
  type        = string
  description = "Name of the services secondary IP range"
  default     = "services"
}

variable "min_node_count" {
  type        = number
  description = "Minimum number of nodes in the node pool"
  default     = 3

  validation {
    condition     = var.min_node_count >= 1 && var.min_node_count <= 1000
    error_message = "Min node count must be between 1 and 1000."
  }
}

variable "max_node_count" {
  type        = number
  description = "Maximum number of nodes in the node pool"
  default     = 10

  validation {
    condition     = var.max_node_count >= 1 && var.max_node_count <= 1000
    error_message = "Max node count must be between 1 and 1000."
  }
}

variable "machine_type" {
  type        = string
  description = "Machine type for GKE nodes"
  default     = "n2-standard-4"

  validation {
    condition     = can(regex("^n[0-9]+-.*", var.machine_type))
    error_message = "Machine type must be a valid GCP machine type (e.g., n2-standard-4)."
  }
}

variable "enable_binary_authorization" {
  type        = bool
  description = "Enable Binary Authorization on the cluster"
  default     = true
}

variable "enable_workload_identity" {
  type        = bool
  description = "Enable Workload Identity on the cluster"
  default     = true
}

variable "enable_gke_dataplane_v2" {
  type        = bool
  description = "Enable GKE Dataplane V2 (eBPF-based network)"
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to all resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
