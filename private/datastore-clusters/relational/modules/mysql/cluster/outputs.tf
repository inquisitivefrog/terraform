output "name" {
  value = var.name
}

output "services" {
  description = "In-cluster DNS names: writer (one node at a time) and readers"
  value = {
    writer  = "${var.name}-haproxy.${var.namespace}.svc:3306"
    readers = "${var.name}-haproxy-replicas.${var.namespace}.svc:3306"
  }
}

output "system_secret" {
  description = "Secret with the operator-generated system passwords (key root for the root user)"
  value       = "${var.name}-secrets"
}
