# modules/identity/resource_grants.tf
# Resource-scoped role assignments, like the AWS policies' Resource lists.

locals {
  id = { for k, v in azurerm_user_assigned_identity.this : k => v.principal_id }

  grants = merge(
    # Developer (AWS: DeveloperPolicy): read the VMs and the dev storage, sign
    { for i, vm in var.vm_ids : "developer-vm-${i}" => { scope = vm, role = "Reader", who = "developer" } },
    {
      developer-data = { scope = var.dev_storage_account_id, role = "Storage Blob Data Reader", who = "developer" }
      developer-sign = { scope = var.asymmetric_key_resource_id, role = "Key Vault Crypto User", who = "developer" }
    },
    # Admin (AWS: AdminPolicy): manage the VMs, storage, cache, app, keys, messaging
    { for i, vm in var.vm_ids : "admin-vm-${i}" => { scope = vm, role = "Virtual Machine Contributor", who = "admin" } },
    {
      admin-data  = { scope = var.dev_storage_account_id, role = "Storage Blob Data Owner", who = "admin" }
      admin-redis = { scope = var.redis_id, role = "Redis Cache Contributor", who = "admin" }
      admin-app   = { scope = var.container_app_id, role = "Container Apps Contributor", who = "admin" }
      admin-keys  = { scope = var.key_vault_id, role = "Key Vault Crypto Officer", who = "admin" }
      admin-bus   = { scope = var.servicebus_namespace_id, role = "Azure Service Bus Data Owner", who = "admin" }
    },
    # VM identity: fetch AKS credentials and administer the cluster
    # (AWS: aws-auth mapped EC2Role to system:masters)
    {
      vm-aks-user  = { scope = var.aks_cluster_id, role = "Azure Kubernetes Service Cluster User Role", who = "vm" }
      vm-aks-admin = { scope = var.aks_cluster_id, role = "Azure Kubernetes Service RBAC Cluster Admin", who = "vm" }
    },
  )
}

resource "azurerm_role_assignment" "grants" {
  for_each             = local.grants
  scope                = each.value.scope
  role_definition_name = each.value.role
  principal_id         = local.id[each.value.who]
}

# Namespace roles (AWS/GCP: Kubernetes Role + RoleBinding). AKS checks these
# Azure role assignments (Azure RBAC for Kubernetes). The custom role allows
# exactly what the AWS roles did: get, list, create and delete pods and services.
resource "azurerm_role_definition" "k8s_pods_services" {
  count       = length(var.namespace_roles) > 0 ? 1 : 0
  name        = "bluedragon-k8s-pods-services-${var.env}"
  scope       = var.aks_cluster_id
  description = "Get, list, create and delete pods and services"

  permissions {
    data_actions = [
      "Microsoft.ContainerService/managedClusters/pods/read",
      "Microsoft.ContainerService/managedClusters/pods/write",
      "Microsoft.ContainerService/managedClusters/pods/delete",
      "Microsoft.ContainerService/managedClusters/services/read",
      "Microsoft.ContainerService/managedClusters/services/write",
      "Microsoft.ContainerService/managedClusters/services/delete",
    ]
  }

  assignable_scopes = [var.aks_cluster_id]
}

resource "azurerm_role_assignment" "namespace" {
  for_each           = var.namespace_roles # who => namespace
  scope              = "${var.aks_cluster_id}/namespaces/${each.value}"
  role_definition_id = azurerm_role_definition.k8s_pods_services[0].role_definition_resource_id
  principal_id       = local.id[each.key]
}
