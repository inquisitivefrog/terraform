# modules/keyvault/keyvault.tf
# Azure counterpart of aws/tfstate/modules/kms (and gcp/tfstate/modules/kms)
# Storage CMK requires purge protection, so a deleted vault's name stays
# reserved for the retention period (7 days here): the name carries the suffix.
# No second key for notifications: Event Grid system topics don't take a CMK.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault

data "azurerm_client_config" "current" {}

# trivy:ignore:AZU-0013 RBAC-only vault reached from a laptop whose IP changes; an IP ACL would lock out state
resource "azurerm_key_vault" "tfstate" {
  name                       = "bdtfkv${var.env}${var.random_suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = {
    Environment = var.env
  }
}

# You create and rotate keys (AWS: the key policy's root statement)
resource "azurerm_role_assignment" "crypto_officer" {
  scope                = azurerm_key_vault.tfstate.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Azure role assignments take a minute or so to apply
resource "time_sleep" "crypto_officer" {
  depends_on      = [azurerm_role_assignment.crypto_officer]
  create_duration = "60s"
}

resource "azurerm_key_vault_key" "state" {
  name         = "state-key"
  key_vault_id = azurerm_key_vault.tfstate.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["wrapKey", "unwrapKey"]

  rotation_policy {
    automatic {
      time_after_creation = "P90D" # like the AWS and GCP keys
    }
    expire_after         = "P180D"
    notify_before_expiry = "P30D"
  }

  depends_on = [time_sleep.crypto_officer]
}

# Identity the state storage account uses to reach the key
resource "azurerm_user_assigned_identity" "storage" {
  name                = "bluedragon-tfstate-${var.env}-storage"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "storage_key" {
  scope                = azurerm_key_vault.tfstate.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage.principal_id
}

resource "time_sleep" "storage_key" {
  depends_on      = [azurerm_role_assignment.storage_key]
  create_duration = "60s"
}
