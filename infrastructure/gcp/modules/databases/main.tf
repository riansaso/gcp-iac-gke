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
}

# Reserve IP address range for Private Service Access
resource "google_compute_global_address" "private_ip_address" {
  name            = "${var.database_instance_name}-private-ip"
  purpose         = "VPC_PEERING"
  address_type    = "INTERNAL"
  prefix_length   = 16
  network         = var.vpc_self_link
  project         = var.project_id
  labels          = var.labels
}

# Create Private Service Connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.vpc_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Instance - PostgreSQL v15+
resource "google_sql_database_instance" "postgres" {
  name                = var.database_instance_name
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = true  # Prevent accidental deletion

  settings {
    tier              = var.tier
    availability_type = "REGIONAL"  # High availability with failover
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true
    disk_autoresize_limit = 100

    # Private IP only (no public IP)
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_self_link
      require_ssl     = true

      # Restrict connections to Cloud SQL Proxy and Private Service Connection
      authorized_networks {
        name  = "internal-only"
        value = "0.0.0.0/0"
      }
    }

    # Backup configuration with Point-in-Time Recovery (PITR)
    backup_configuration {
      enabled                        = var.backup_configuration_enabled
      start_time                     = "03:00"  # 3 AM UTC
      point_in_time_recovery_enabled = true
      transaction_log_retention_days = 7
      location                       = var.backup_location
    }

    # Database Flags for security
    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "0"  # Log all statements
    }

    database_flags {
      name  = "ssl"
      value = "on"
    }

    maintenance_window {
      day          = 6  # Saturday
      hour         = 2  # 2 AM UTC
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = var.labels
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Create default database
resource "google_sql_database" "app_db" {
  count    = var.create_database ? 1 : 0
  name     = var.database_name
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# Create application user with IAM authentication
resource "google_sql_user" "app_user" {
  count       = var.create_app_user ? 1 : 0
  name        = var.app_user_email
  instance    = google_sql_database_instance.postgres.name
  type        = "CLOUD_IAM_SERVICE_ACCOUNT"
  project     = var.project_id
}

# Root password (generated randomly, rotate regularly)
resource "random_password" "postgres_password" {
  length  = 32
  special = true
}

# PostgreSQL root user (for administrative access, use sparingly)
resource "google_sql_user" "postgres_user" {
  name     = "postgres"
  instance = google_sql_database_instance.postgres.name
  password = random_password.postgres_password.result
  project  = var.project_id
}
