# azure/single_instance/environments outputs

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kubernetes_version" {
  value = module.aks.kubernetes_version
}

output "container_app_fqdn" {
  description = "Internal-only nginx; reachable from inside the VNet"
  value       = module.compute.container_app_fqdn
}

output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "kubeconfig_command" {
  description = "Admin credentials into a separate kubeconfig (never ~/.kube/config)"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name} --subscription ${var.subscription_id} --admin --file ~/.kube/azure-${var.env}"
}

output "private_vm_ip" {
  value = module.compute.private_vm_ip
}

output "public_vm_ip" {
  value = module.compute.public_vm_ip
}

output "redis_hostname" {
  value = module.cache.redis_hostname
}

output "redis_port" {
  value = module.cache.redis_port
}

output "redis_access_key" {
  value     = module.cache.redis_access_key
  sensitive = true
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "servicebus_namespace" {
  value = module.messages.servicebus_namespace_name
}

output "ssh_user" {
  value = module.compute.admin_username
}

output "subscription_id" {
  value = var.subscription_id
}
