terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Memorystore for Redis instance with Private Service Connection
resource "google_redis_instance" "primary" {
  name               = var.redis_instance_name
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  project            = var.project_id
  tier               = var.tier
  redis_version      = var.redis_version
  redis_configs = {
    "maxmemory-policy" = "allkeys-lru"  # Eviction policy for memory management
  }

  # Use Private Service Connection for secure networking
  connect_mode = "PRIVATE_SERVICE_ACCESS"
  network      = var.vpc_network

  # Authorization network for Private Service Access
  authorized_network = var.authorized_network != "" ? var.authorized_network : null

  # Persistence for data durability
  persistence_config {
    persistence_type = "RDB"
    rdb_snapshot_period = "TWELVE_HOURS"
  }

  labels = var.labels

  depends_on = []
}
