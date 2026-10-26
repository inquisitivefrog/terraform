output "name" {
  value = var.name
}

output "services" {
  description = "In-cluster DNS names: read-write (always the primary), read-only (replicas)"
  value = {
    read_write = "${var.name}-rw.${var.namespace}.svc:5432"
    read_only  = "${var.name}-ro.${var.namespace}.svc:5432"
  }
}

output "app_secret" {
  description = "Secret with the application role's username, password and connection URI"
  value       = "${var.name}-app"
}
