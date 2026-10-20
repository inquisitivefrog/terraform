# modules/keyvault/outputs.tf

output "aks_kms_key_id" {
  description = "Versioned key ID (AKS KMS needs the version)"
  value       = azurerm_key_vault_key.rotating["aks-kms-key"].id
}

output "asymmetric_key_resource_id" {
  value = azurerm_key_vault_key.asymmetric.resource_id
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "storage_cmk" {
  description = "Key and identity for the storage accounts' customer-managed key"
  value = {
    key_id      = azurerm_key_vault_key.rotating["messages-key"].versionless_id
    identity_id = azurerm_user_assigned_identity.storage.id
  }
  depends_on = [time_sleep.storage_key]
}
