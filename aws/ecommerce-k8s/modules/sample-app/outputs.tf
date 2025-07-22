output "service" {
  description = "Sample app service details"
  value       = kubernetes_service.app.metadata[0]
}
