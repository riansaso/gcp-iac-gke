output "instance_connection_name" {
  value       = google_sql_database_instance.postgres.connection_name
  description = "Connection string for Cloud SQL Proxy (project:region:instance)"
}

output "private_ip_address" {
  value       = google_sql_database_instance.postgres.private_ip_address
  description = "Private IP address of the Cloud SQL instance"
}

output "instance_self_link" {
  value       = google_sql_database_instance.postgres.self_link
  description = "Self-link of the Cloud SQL instance"
}

output "database_name" {
  value       = var.create_database ? google_sql_database.app_db[0].name : null
  description = "Name of the application database"
}

output "app_user_name" {
  value       = var.create_app_user ? google_sql_user.app_user[0].name : null
  description = "IAM service account name for application user"
}

output "service_connection_name" {
  value       = google_service_networking_connection.private_vpc_connection.service
  description = "Name of the service networking connection"
}
