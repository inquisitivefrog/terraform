output "url" {
  description = "In-cluster base URL"
  value       = "http://${var.name}.${var.namespace}.svc:8080"
}
