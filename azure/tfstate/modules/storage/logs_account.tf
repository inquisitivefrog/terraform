# modules/storage/logs_account.tf
# Azure counterpart of aws/tfstate/modules/storage/s3_state_log_bucket.tf
# Diagnostic logs land in containers named insights-logs-<category>.

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

  # Microsoft-managed keys, like the S3 log bucket's SSE-S3
  blob_properties {
    versioning_enabled = true
  }

  tags = merge(local.tags, { Purpose = "logs" })
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
