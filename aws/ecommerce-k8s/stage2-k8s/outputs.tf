output "ingress_hostname" {
  value       = try(kubernetes_ingress_v1.ecommerce_app.status[0].load_balancer[0].ingress[0].hostname, "pending")
  description = "Hostname of the ALB for ecommerce-app"
}
