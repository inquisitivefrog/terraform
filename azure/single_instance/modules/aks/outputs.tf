# modules/aks/outputs.tf

output "cluster_id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "kubernetes_version" {
  value = azurerm_kubernetes_cluster.this.current_kubernetes_version
}

output "kube_admin_config" {
  description = "Local admin credentials, for Terraform's kubernetes provider"
  value = {
    host                   = azurerm_kubernetes_cluster.this.kube_admin_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.this.kube_admin_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.this.kube_admin_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.this.kube_admin_config[0].cluster_ca_certificate
  }
  sensitive = true
}
