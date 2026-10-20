# modules/messages/eventgrid.tf
# Azure counterpart of aws/tfstate/modules/messages/sns.tf
# A system topic publishes the state account's blob events (S3 event
# notifications to SNS). Like the SNS topic, nothing subscribes yet; add an
# azurerm_eventgrid_system_topic_event_subscription to deliver them.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/eventgrid_system_topic

resource "azurerm_eventgrid_system_topic" "state" {
  name                = "bluedragon-tfstate-${var.env}-events"
  location            = var.location
  resource_group_name = var.resource_group_name
  source_resource_id  = var.storage_account_id
  topic_type          = "Microsoft.Storage.StorageAccounts"

  tags = {
    Environment = var.env
  }
}
