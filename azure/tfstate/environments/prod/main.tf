# azure/tfstate/environments/prod/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.10"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.14"
    }
  }
  backend "azurerm" {} # see backend.hcl
}

provider "azurerm" {
  subscription_id                 = var.subscription_id
  storage_use_azuread             = true
  resource_provider_registrations = "none" # azure/scripts/register_providers.sh does it, once
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false # purge protection forbids it
      recover_soft_deleted_key_vaults = false
    }
  }
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false # storage account names are lowercase
}

resource "azurerm_resource_group" "tfstate" {
  name     = "bluedragon-tfstate-${var.env}-${random_string.suffix.result}-rg"
  location = var.location
  tags = {
    Environment = var.env
  }
}

module "keyvault" {
  source              = "../../modules/keyvault"
  env                 = var.env
  location            = azurerm_resource_group.tfstate.location
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.tfstate.name
}

module "storage" {
  source              = "../../modules/storage"
  cmk                 = module.keyvault.state_cmk
  data_principal_id   = data.azurerm_client_config.current.object_id
  employer            = var.employer
  env                 = var.env
  location            = azurerm_resource_group.tfstate.location
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.tfstate.name
}

module "messages" {
  source              = "../../modules/messages"
  env                 = var.env
  location            = azurerm_resource_group.tfstate.location
  resource_group_name = azurerm_resource_group.tfstate.name
  storage_account_id  = module.storage.state_account_id
}
