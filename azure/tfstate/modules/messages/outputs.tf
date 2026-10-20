# modules/messages/outputs.tf

output "system_topic_id" {
  value = azurerm_eventgrid_system_topic.state.id
}
