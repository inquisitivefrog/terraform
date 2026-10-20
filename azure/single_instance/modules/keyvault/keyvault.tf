# modules/keyvault/keyvault.tf
# Azure counterpart of aws/single_instance/modules/kms (and gcp's)
# Purge protection (needed for storage CMK and AKS KMS) reserves a deleted
# vault's name for 7 days, so the name carries the random suffix.
# Standard vaults hold RSA/EC keys only (AES needs Managed HSM), so the
# AWS "symmetric" example key becomes an RSA encrypt/decrypt key.
# No flow-logs key (flow logs go to a storage account) and no Service Bus key
# (customer-managed keys need the Premium tier).

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = "bdsikv${var.env}${var.random_suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags                       = var.tags
}

# You create and rotate keys
resource "azurerm_role_assignment" "crypto_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "crypto_officer" {
  depends_on      = [azurerm_role_assignment.crypto_officer]
  create_duration = "60s" # role assignments take a minute to apply
}

locals {
  rotating_keys = {
    aks-kms-key   = { size = 2048, opts = ["encrypt", "decrypt", "wrapKey", "unwrapKey"] } # AWS: eks_key
    messages-key  = { size = 3072, opts = ["wrapKey", "unwrapKey"] }                       # AWS: sns_custom_key (storage CMK)
    symmetric-key = { size = 2048, opts = ["encrypt", "decrypt"] }                         # AWS: symmetric_key
  }
}

resource "azurerm_key_vault_key" "rotating" {
  for_each     = local.rotating_keys
  name         = each.key
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = each.value.size
  key_opts     = each.value.opts

  rotation_policy {
    automatic {
      time_after_creation = "P90D"
    }
    expire_after         = "P180D"
    notify_before_expiry = "P30D"
  }

  depends_on = [time_sleep.crypto_officer]
}

# AWS: asymmetric_key (RSA-3072 sign/verify, no rotation)
resource "azurerm_key_vault_key" "asymmetric" {
  name         = "asymmetric-key"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 3072
  key_opts     = ["sign", "verify"]

  depends_on = [time_sleep.crypto_officer]
}

# Identity the dev and log storage accounts use to reach messages-key
resource "azurerm_user_assigned_identity" "storage" {
  name                = "id-storage-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "storage_key" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.storage.principal_id
}

resource "time_sleep" "storage_key" {
  depends_on      = [azurerm_role_assignment.storage_key]
  create_duration = "60s"
}
