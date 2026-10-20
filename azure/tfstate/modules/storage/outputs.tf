# modules/storage/outputs.tf

output "logs_account_name" {
  value = azurerm_storage_account.logs.name
}

output "state_account_id" {
  value = azurerm_storage_account.state.id
}

output "state_account_name" {
  value = azurerm_storage_account.state.name
}
