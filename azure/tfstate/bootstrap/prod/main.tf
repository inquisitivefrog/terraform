# azure/tfstate/bootstrap/prod/main.tf
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
  name     = "bluedragon-tfstate-prod-rg"
  location = "westus"
  tags = {
    Environment = "prod"
  }
}

module "storage" {
  source              = "../../modules/storage"
  data_principal_id   = data.azurerm_client_config.current.object_id
  employer            = "Fireworks Inc"
  env                 = "prod"
  location            = azurerm_resource_group.tfstate.location
  random_suffix       = ""
  resource_group_name = azurerm_resource_group.tfstate.name
}

output "backend_storage_account" {
  value = module.storage.state_account_name
}
