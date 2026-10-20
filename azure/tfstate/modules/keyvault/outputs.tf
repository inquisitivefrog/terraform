# modules/keyvault/outputs.tf

output "key_vault_name" {
  value = azurerm_key_vault.tfstate.name
}

output "state_cmk" {
  description = "Key and identity for the state account's customer-managed key"
  value = {
    key_id      = azurerm_key_vault_key.state.versionless_id
    identity_id = azurerm_user_assigned_identity.storage.id
  }
  depends_on = [time_sleep.storage_key] # the identity needs its role first
}
