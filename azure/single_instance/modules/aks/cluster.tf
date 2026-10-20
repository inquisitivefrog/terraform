# modules/aks/cluster.tf
# Azure counterpart of aws/single_instance/modules/eks (and gcp's gke)
# Free tier (no cluster fee), nodes in the private subnet with egress through
# the NAT gateway, API restricted to the authorized CIDRs, etcd secrets
# encrypted with a Key Vault key (KMS), Workload Identity, Azure CNI overlay
# with the Cilium data plane (GKE: Dataplane V2). Entra ID integration with
# Azure RBAC decides who can do what in the cluster; local admin credentials
# stay enabled so Terraform's kubernetes provider needs no kubelogin.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster

data "azurerm_client_config" "current" {}

# Control plane identity: reads the KMS key, joins the private subnet
resource "azurerm_role_assignment" "kms" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = var.cluster_identity_principal_id
}

resource "azurerm_role_assignment" "subnet" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.cluster_identity_principal_id
}

resource "time_sleep" "roles" {
  depends_on      = [azurerm_role_assignment.kms, azurerm_role_assignment.subnet]
  create_duration = "60s"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                      = "aks-${var.env}-${var.random_suffix}"
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = "aks-${var.env}-${var.random_suffix}"
  sku_tier                  = "Free"
  kubernetes_version        = var.kubernetes_version # null: AKS default
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = false
  tags                      = var.tags

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    node_count                  = var.node_count
    auto_scaling_enabled        = true
    min_count                   = 1
    max_count                   = var.node_max_count
    vnet_subnet_id              = var.subnet_id
    os_disk_size_gb             = 30
    os_disk_type                = "Managed"
    temporary_name_for_rotation = "systemtmp"

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cluster_identity_id]
  }

  node_provisioning_profile {
    mode = "Manual" # the node pool above, not node auto-provisioning (Karpenter)
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.pods_cidr_block
    service_cidr        = var.services_cidr_block
    dns_service_ip      = cidrhost(var.services_cidr_block, 10)
    outbound_type       = "userAssignedNATGateway"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_cidrs
  }

  key_management_service {
    key_vault_key_id         = var.kms_key_id
    key_vault_network_access = "Public"
  }

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  # Managed NGINX ingress (AWS: ALB controller chart + IAM role)
  dynamic "web_app_routing" {
    for_each = var.enable_ingress ? [1] : []
    content {
      dns_zone_ids = []
    }
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count] # the autoscaler owns it
  }

  depends_on = [time_sleep.roles]
}

# You administer the cluster through Entra ID too (az aks get-credentials without --admin)
resource "azurerm_role_assignment" "me_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
