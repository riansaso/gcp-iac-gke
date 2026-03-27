output "redis_host" {
  value       = google_redis_instance.primary.host
  description = "Redis instance host address"
}

output "redis_port" {
  value       = google_redis_instance.primary.port
  description = "Redis instance port"
}

output "redis_auth_string" {
  value       = google_redis_instance.primary.auth_string
  description = "AUTH string for Redis (empty if no auth)"
  sensitive   = true
}

output "redis_connection_string" {
  value       = "redis://${google_redis_instance.primary.host}:${google_redis_instance.primary.port}"
  description = "Redis connection string"
}
