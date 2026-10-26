output "cluster_name" {
  value = module.platform.name
}

output "kubeconfig_path" {
  value = module.platform.kubeconfig_path
}

output "context_name" {
  value = module.platform.context_name
}

output "endpoint" {
  value = module.platform.endpoint
}

output "zones" {
  value = module.platform.zones
}

output "kubectl" {
  description = "Use the cluster from a shell (only that shell)"
  value       = "export KUBECONFIG=${module.platform.kubeconfig_path}"
}
