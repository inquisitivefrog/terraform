# modules/cache/outputs.tf

output "redis_host" {
  value = google_redis_instance.main.host
}

output "redis_id" {
  value = google_redis_instance.main.id
}

output "redis_port" {
  value = google_redis_instance.main.port
}

output "redis_auth_string" {
  value     = google_redis_instance.main.auth_string
  sensitive = true
}

output "redis_server_ca_cert" {
  value = google_redis_instance.main.server_ca_certs[0].cert
}
