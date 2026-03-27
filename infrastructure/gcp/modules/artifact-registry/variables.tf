variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "GCP region for artifact repositories"
}

variable "create_docker_repo" {
  type        = bool
  description = "Create Docker/OCI container image repository"
  default     = true
}

variable "create_helm_repo" {
  type        = bool
  description = "Create Helm chart repository"
  default     = true
}

variable "docker_repo_name" {
  type        = string
  description = "Name of the Docker repository"
  default     = "docker-repo"
}

variable "helm_repo_name" {
  type        = string
  description = "Name of the Helm repository"
  default     = "helm-repo"
}

variable "labels" {
  type        = map(string)
  description = "Labels to apply to resources"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
