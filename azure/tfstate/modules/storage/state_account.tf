# modules/storage/state_account.tf
# Azure counterpart of aws/tfstate/modules/storage/s3_state_bucket.tf
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account

locals {
  # Storage account names: 3-24 lowercase letters and digits, globally unique
  state_account_name = "bdtfstate${var.env}${var.random_suffix}"
  logs_account_name  = "bdtflogs${var.env}${var.random_suffix}"

  tags = {
    Employer    = var.employer
    Environment = var.env
  }
}

# trivy:ignore:AZU-0012 Entra ID only (shared keys off); an IP deny rule would lock out the laptop
resource "azurerm_storage_account" "state" {
  name                     = local.state_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # No shared keys or SAS: access only through Entra ID roles (AWS: IAM only)
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  allow_nested_items_to_be_public = false # AWS: public access block
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  # CMK through a user-assigned identity (environments); Microsoft-managed keys otherwise (bootstrap)
  dynamic "identity" {
    for_each = var.cmk == null ? [] : [var.cmk]
    content {
      type         = "UserAssigned"
      identity_ids = [identity.value.identity_id]
    }
  }

  dynamic "customer_managed_key" {
    for_each = var.cmk == null ? [] : [var.cmk]
    content {
      key_vault_key_id          = customer_managed_key.value.key_id # versionless: follows rotation
      user_assigned_identity_id = customer_managed_key.value.identity_id
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

# Old versions: Cool tier after 30 days (S3: Glacier; azurerm has no Cold
# option for versions), deleted after 365.
# Azure discards uncommitted blocks itself after 7 days (S3: abort multipart).
resource "azurerm_storage_management_policy" "state" {
  storage_account_id = azurerm_storage_account.state.id

  rule {
    name    = "old-versions"
    enabled = true
    filters {
      blob_types = ["blockBlob"]
    }
    actions {
      version {
        change_tier_to_cool_after_days_since_creation = 30
        delete_after_days_since_creation              = 365
      }
    }
  }
}

# Your Entra ID login reads and writes state (backend use_azuread_auth).
# Owner on the subscription doesn't include blob data access.
resource "azurerm_role_assignment" "state_data" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_principal_id
}

# Access logs to the logs account (AWS: S3 server access logging)
resource "azurerm_monitor_diagnostic_setting" "state_blob" {
  name               = "state-access-logs"
  target_resource_id = "${azurerm_storage_account.state.id}/blobServices/default"
  storage_account_id = azurerm_storage_account.logs.id

  enabled_log {
    category_group = "allLogs"
  }
}
