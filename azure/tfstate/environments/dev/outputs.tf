output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "state_account_name" {
  value = module.storage.state_account_name
}

output "logs_account_name" {
  value = module.storage.logs_account_name
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}
