# modules/storage/storage.tf
# Azure counterpart of aws/single_instance/modules/storage (and gcp's)
# Dev account: CMK (messages-key, AWS: sns_custom_key), versioning, a "logs"
# container whose blobs expire after 90 days and raise events. Logs account:
# access logs from the dev account plus VNet flow logs, kept 365 days.

locals {
  # 3-24 lowercase letters and digits, globally unique
  dev_account_name  = "bdsidata${var.env}${var.random_suffix}"
  logs_account_name = "bdsilogs${var.env}${var.random_suffix}"
}

resource "azurerm_storage_account" "dev" {
  name                     = local.dev_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cmk.identity_id]
  }

  customer_managed_key {
    key_vault_key_id          = var.cmk.key_id
    user_assigned_identity_id = var.cmk.identity_id
  }

  tags = merge(var.tags, { Name = "bluedragon-dev-bucket" })
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_id    = azurerm_storage_account.dev.id
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "dev" {
  storage_account_id = azurerm_storage_account.dev.id

  rule {
    name    = "expire-logs"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"] # container "logs"
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}

resource "azurerm_storage_account" "logs" {
  name                     = local.logs_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cmk.identity_id]
  }

  customer_managed_key {
    key_vault_key_id          = var.cmk.key_id
    user_assigned_identity_id = var.cmk.identity_id
  }

  tags = merge(var.tags, { Name = "bluedragon-log-bucket" })
}

resource "azurerm_storage_management_policy" "logs" {
  storage_account_id = azurerm_storage_account.logs.id

  rule {
    name    = "expire-logs"
    enabled = true
    filters {
      blob_types = ["blockBlob", "appendBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 365
      }
      version {
        delete_after_days_since_creation = 365
      }
    }
  }
}

# Access logs (AWS: S3 server access logging to the log bucket)
resource "azurerm_monitor_diagnostic_setting" "dev_blob" {
  name               = "dev-access-logs"
  target_resource_id = "${azurerm_storage_account.dev.id}/blobServices/default"
  storage_account_id = azurerm_storage_account.logs.id

  enabled_log {
    category_group = "allLogs"
  }
}

# You read logs and data with your Entra ID login (shared keys are off;
# Owner on the subscription doesn't include blob data access)
data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "me_read" {
  for_each = {
    dev  = azurerm_storage_account.dev.id
    logs = azurerm_storage_account.logs.id
  }
  scope                = each.value
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
