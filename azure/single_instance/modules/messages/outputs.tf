# modules/messages/outputs.tf

output "servicebus_namespace_id" {
  value = azurerm_servicebus_namespace.this.id
}

output "servicebus_namespace_name" {
  value = azurerm_servicebus_namespace.this.name
}
