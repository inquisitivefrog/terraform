# modules/messages/servicebus.tf
# Azure counterpart of aws/single_instance/modules/messages/sns.tf
# Service Bus Standard (topics need it; customer-managed keys need Premium).
# example-topic gets blob-created events from the dev account's "logs"
# container through Event Grid (AWS: S3 notification to SNS). AWS's https
# subscription to example.com is left out: Event Grid webhooks must answer a
# validation handshake, which example.com can't.
# custom-topic stands in for the SNS FIFO topic: duplicate detection plus a
# session-enabled subscription gives ordered, de-duplicated delivery.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/servicebus_namespace

resource "azurerm_servicebus_namespace" "this" {
  name                = "sb-bluedragon-${var.env}-${var.random_suffix}" # global DNS name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  minimum_tls_version = "1.2"
  local_auth_enabled  = false # Entra ID only, no SAS keys
  tags                = var.tags
}

resource "azurerm_servicebus_topic" "example" {
  name         = "example-topic"
  namespace_id = azurerm_servicebus_namespace.this.id
}

resource "azurerm_servicebus_subscription" "example" {
  name               = "example-sub"
  topic_id           = azurerm_servicebus_topic.example.id
  max_delivery_count = 3 # AWS delivery policy: numRetries 3
}

resource "azurerm_servicebus_topic" "custom" {
  name                                    = "custom-topic"
  namespace_id                            = azurerm_servicebus_namespace.this.id
  support_ordering                        = true
  duplicate_detection_history_time_window = "PT10M"
  requires_duplicate_detection            = true
}

resource "azurerm_servicebus_subscription" "custom" {
  name               = "custom-ordered"
  topic_id           = azurerm_servicebus_topic.custom.id
  requires_session   = true
  max_delivery_count = 10
}

# Blob events from the dev account into example-topic
resource "azurerm_eventgrid_system_topic" "dev_storage" {
  name                = "evgt-dev-storage-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  source_resource_id  = var.dev_storage_account_id
  topic_type          = "Microsoft.Storage.StorageAccounts"
  tags                = var.tags

  identity {
    type = "SystemAssigned" # delivers to Service Bus with Entra ID (SAS is off)
  }
}

resource "azurerm_role_assignment" "eventgrid_sender" {
  scope                = azurerm_servicebus_topic.example.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.dev_storage.identity[0].principal_id
}

resource "azurerm_eventgrid_system_topic_event_subscription" "logs_to_example" {
  name                = "logs-created"
  system_topic        = azurerm_eventgrid_system_topic.dev_storage.name
  resource_group_name = var.resource_group_name

  included_event_types = ["Microsoft.Storage.BlobCreated"]
  subject_filter {
    subject_begins_with = "/blobServices/default/containers/logs/" # AWS: filter_prefix logs/
  }

  delivery_identity {
    type = "SystemAssigned"
  }
  service_bus_topic_id = azurerm_servicebus_topic.example.id

  depends_on = [azurerm_role_assignment.eventgrid_sender]
}
