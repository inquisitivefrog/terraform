output "ingress_hostname" {
  value       = try(kubernetes_ingress_v1.ecommerce_app.status[0].load_balancer[0].ingress[0].hostname, "pending")
  description = "Hostname of the ALB for ecommerce-app"
}

output "aws_auth_configmap" {
  description = "AWS auth ConfigMap details"
  value       = kubernetes_config_map_v1.aws_auth.metadata
}

output "bluedragon_admin_role" {
  description = "Bluedragon admin ClusterRoleBinding details"
  value       = kubernetes_manifest.bluedragon_admin_clusterrolebinding.manifest.metadata
}
