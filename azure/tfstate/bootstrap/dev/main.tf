# azure/tfstate/bootstrap/dev/main.tf
# create the Azure storage account that holds terraform.tfstate files (state for this root is local)

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
  }
}

provider "azurerm" {
  subscription_id                 = var.subscription_id # bluedragon-sre, never the az CLI default
  storage_use_azuread             = true                # storage accounts have shared keys disabled
  resource_provider_registrations = "none"              # azure/scripts/register_providers.sh does it, once
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "tfstate" {
  name     = "bluedragon-tfstate-dev-rg"
  location = "westus2"
  tags = {
    Environment = "dev"
  }
}

module "storage" {
  source              = "../../modules/storage"
  data_principal_id   = data.azurerm_client_config.current.object_id
  employer            = "Fireworks Inc"
  env                 = "dev"
  location            = azurerm_resource_group.tfstate.location
  random_suffix       = ""
  resource_group_name = azurerm_resource_group.tfstate.name
}

# Subscription-wide alert, so it lives in one root only (dev). Azure budgets
# alert; they never stop spending (the subscription has no spending limit).
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "bluedragon-sre-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z" # first of a month, required
  }

  notification {
    operator       = "GreaterThan"
    threshold      = 80
    threshold_type = "Actual"
    contact_emails = [var.budget_email]
  }

  notification {
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_emails = [var.budget_email]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

output "backend_storage_account" {
  value = module.storage.state_account_name
}
