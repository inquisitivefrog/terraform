# modules/storage/outputs.tf

output "dev_account_id" {
  value = azurerm_storage_account.dev.id
}

output "dev_account_name" {
  value = azurerm_storage_account.dev.name
}

output "logs_account_id" {
  value = azurerm_storage_account.logs.id
}

output "logs_account_name" {
  value = azurerm_storage_account.logs.name
}
