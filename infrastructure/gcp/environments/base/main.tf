terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Uncomment to use Cloud Storage backend for state
  # backend "gcs" {
  #   bucket  = "YOUR_PROJECT_ID-terraform-state"
  #   prefix  = "gcp-iac-gke/base"
  # }
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required GCP APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "servicenetworking.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ==========================================
# Networking Module
# ==========================================
module "networking" {
  source = "../../modules/networking"

  project_id        = var.project_id
  region            = var.region
  vpc_name          = "${var.project_name}-vpc"
  primary_cidr      = var.vpc_primary_cidr
  gke_nodes_cidr    = var.gke_nodes_cidr
  pods_cidr         = var.pods_cidr
  services_cidr     = var.services_cidr
  labels            = var.labels

  depends_on = [google_project_service.required_apis]
}

# ==========================================
# GKE Module
# ==========================================
module "gke" {
  source = "../../modules/gke"

  project_id                      = var.project_id
  region                          = var.region
  cluster_name                    = "${var.project_name}-gke"
  vpc_self_link                   = module.networking.vpc_self_link
  gke_nodes_subnet_self_link      = module.networking.gke_nodes_subnet_self_link
  pods_secondary_range_name       = "pods"
  services_secondary_range_name   = "services"
  min_node_count                  = var.gke_min_nodes
  max_node_count                  = var.gke_max_nodes
  machine_type                    = var.gke_machine_type
  enable_binary_authorization     = var.enable_binary_authorization
  enable_workload_identity        = var.enable_workload_identity
  enable_gke_dataplane_v2         = var.enable_gke_dataplane_v2
  labels                          = var.labels

  depends_on = [module.networking, google_project_service.required_apis]
}

# ==========================================
# IAM Module
# ==========================================
module "iam" {
  source = "../../modules/iam"

  project_id                       = var.project_id
  cluster_workload_identity_pool   = module.gke.workload_identity_pool
  cluster_location                 = var.region
  create_external_secrets_sa       = true
  create_flux_sa                   = true
  create_app_sa                    = true
  namespace_external_secrets       = "external-secrets"
  namespace_flux_system            = "flux-system"
  namespace_applications           = "applications"
  labels                           = var.labels

  depends_on = [module.gke, google_project_service.required_apis]
}

# ==========================================
# Databases Module (PostgreSQL)
# ==========================================
module "postgres" {
  source = "../../modules/databases"

  project_id                = var.project_id
  region                    = var.region
  vpc_self_link             = module.networking.vpc_self_link
  database_instance_name    = "${var.project_name}-postgres"
  database_version          = var.postgres_version
  tier                      = var.postgres_tier
  disk_size_gb              = var.postgres_disk_size_gb
  backup_configuration_enabled = true
  enable_iam_authentication = true
  create_database           = true
  database_name             = var.postgres_database_name
  create_app_user           = true
  app_user_email            = module.iam.app_sa_email
  labels                    = var.labels

  depends_on = [module.iam, module.networking, google_project_service.required_apis]
}

# ==========================================
# Redis Module
# ==========================================
module "redis" {
  source = "../../modules/databases/redis"

  project_id         = var.project_id
  region             = var.region
  redis_instance_name = "${var.project_name}-redis"
  redis_version      = var.redis_version
  memory_size_gb     = var.redis_memory_size_gb
  tier               = var.redis_tier
  vpc_network        = module.networking.vpc_name
  labels             = var.labels

  depends_on = [module.networking, google_project_service.required_apis]
}

# ==========================================
# Artifact Registry Module
# ==========================================
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id           = var.project_id
  region               = var.region
  create_docker_repo   = true
  create_helm_repo     = true
  docker_repo_name     = "${var.project_name}-docker"
  helm_repo_name       = "${var.project_name}-helm"
  labels               = var.labels

  depends_on = [google_project_service.required_apis]
}

# ==========================================
# Secrets Manager Module
# ==========================================
module "secrets" {
  source = "../../modules/secrets"

  project_id              = var.project_id
  region                  = var.region
  create_example_secret   = true
  example_secret_name     = "${var.project_name}-db-url"
  labels                  = var.labels

  depends_on = [google_project_service.required_apis]
}
