# File 45: ../../modules/kubernetes/outputs.tf

output "namespace_names" {
  value       = [for ns in kubernetes_namespace.namespaces : ns.metadata[0].name]
  description = "Names of created namespaces"
}
