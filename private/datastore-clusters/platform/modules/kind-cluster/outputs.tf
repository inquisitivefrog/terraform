output "name" {
  value = kind_cluster.this.name
}

output "kubeconfig_path" {
  value = var.kubeconfig_path
}

output "context_name" {
  description = "kubectl context in kubeconfig_path (kind names it kind-<name>)"
  value       = "kind-${kind_cluster.this.name}"
}

output "endpoint" {
  description = "API server, published on 127.0.0.1 only"
  value       = kind_cluster.this.endpoint
}

output "zones" {
  value = var.zones
}
