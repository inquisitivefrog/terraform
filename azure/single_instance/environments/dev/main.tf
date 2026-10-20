# azure/single_instance/environments/dev/main.tf

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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.4"
    }
  }
  backend "azurerm" {} # see backend.hcl
}

provider "azurerm" {
  subscription_id                 = var.subscription_id # bluedragon-sre, never the az CLI default
  storage_use_azuread             = true                # storage accounts have shared keys disabled
  resource_provider_registrations = "none"              # azure/scripts/register_providers.sh does it, once
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false # purge protection forbids it
      recover_soft_deleted_key_vaults = false
    }
  }
}

provider "kubernetes" {
  host                   = module.aks.kube_admin_config.host
  client_certificate     = base64decode(module.aks.kube_admin_config.client_certificate)
  client_key             = base64decode(module.aks.kube_admin_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_admin_config.cluster_ca_certificate)
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false # storage account names are lowercase
}

locals {
  tags = {
    Employer    = var.employer
    Environment = var.env
  }
}

resource "azurerm_resource_group" "this" {
  name     = "bluedragon-single-instance-${var.env}-rg"
  location = var.location
  tags     = local.tags
}

module "vpc" {
  source                      = "../../modules/vpc"
  env                         = var.env
  flow_log_storage_account_id = module.storage.logs_account_id
  location                    = azurerm_resource_group.this.location
  resource_group_name         = azurerm_resource_group.this.name
  tags                        = local.tags
  vpc_cidr_block              = var.vpc_cidr_block
}

module "networking" {
  source                      = "../../modules/networking"
  env                         = var.env
  location                    = azurerm_resource_group.this.location
  my_laptop_cidr_block        = var.my_laptop_cidr_block
  redis_port                  = module.cache.redis_port # 10000, TLS
  resource_group_name         = azurerm_resource_group.this.name
  subnet_apps_cidr_block      = module.vpc.subnet_apps_cidr_block
  subnet_endpoints_cidr_block = module.vpc.subnet_endpoints_cidr_block
  subnet_private_cidr_block   = module.vpc.subnet_private_cidr_block
  subnet_public_cidr_block    = module.vpc.subnet_public_cidr_block
  tags                        = local.tags
  vpc_cidr_block              = var.vpc_cidr_block
}

module "keyvault" {
  source              = "../../modules/keyvault"
  env                 = var.env
  location            = azurerm_resource_group.this.location
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "identity" {
  source                     = "../../modules/identity"
  aks_cluster_id             = module.aks.cluster_id
  asymmetric_key_resource_id = module.keyvault.asymmetric_key_resource_id
  container_app_id           = module.compute.container_app_id
  dev_storage_account_id     = module.storage.dev_account_id
  env                        = var.env
  key_vault_id               = module.keyvault.key_vault_id
  location                   = azurerm_resource_group.this.location
  namespace_roles            = { sre = "app1", dba = "app2" }
  redis_id                   = module.cache.redis_id
  resource_group_name        = azurerm_resource_group.this.name
  servicebus_namespace_id    = module.messages.servicebus_namespace_id
  tags                       = local.tags
  vm_ids                     = module.compute.vm_ids
}

module "storage" {
  source              = "../../modules/storage"
  cmk                 = module.keyvault.storage_cmk
  env                 = var.env
  location            = azurerm_resource_group.this.location
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "messages" {
  source                 = "../../modules/messages"
  dev_storage_account_id = module.storage.dev_account_id
  env                    = var.env
  location               = azurerm_resource_group.this.location
  random_suffix          = random_string.suffix.result
  resource_group_name    = azurerm_resource_group.this.name
  tags                   = local.tags
}

module "cache" {
  source              = "../../modules/cache"
  env                 = var.env
  location            = azurerm_resource_group.this.location
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.this.name
  subnet_endpoints_id = module.vpc.subnet_endpoints_id
  tags                = local.tags
  vnet_id             = module.vpc.vnet_id
}

module "compute" {
  source              = "../../modules/compute"
  aca_identity_id     = module.identity.identities["aca"].id
  env                 = var.env
  location            = azurerm_resource_group.this.location
  nsg_private_vm_id   = module.networking.nsg_private_vm_id
  nsg_public_vm_id    = module.networking.nsg_public_vm_id
  random_suffix       = random_string.suffix.result
  resource_group_name = azurerm_resource_group.this.name
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  subnet_apps_id      = module.vpc.subnet_apps_id
  subnet_private_id   = module.vpc.subnet_private_id
  subnet_public_id    = module.vpc.subnet_public_id
  tags                = local.tags
  vm_identity_id      = module.identity.identities["vm"].id
  vm_size             = var.vm_size
  vnet_id             = module.vpc.vnet_id
}

module "aks" {
  source = "../../modules/aks"
  authorized_cidrs = [
    var.my_laptop_cidr_block,
    "${module.vpc.nat_public_ip}/32",    # nodes reach the API through the NAT gateway
    "${module.compute.public_vm_ip}/32", # kubectl from the public VM
  ]
  cluster_identity_id           = module.identity.identities["aks"].id
  cluster_identity_principal_id = module.identity.identities["aks"].principal_id
  enable_ingress                = var.enable_ingress
  env                           = var.env
  key_vault_id                  = module.keyvault.key_vault_id
  kms_key_id                    = module.keyvault.aks_kms_key_id
  location                      = azurerm_resource_group.this.location
  node_count                    = var.aks_node_count
  node_max_count                = var.aks_node_max_count
  node_vm_size                  = var.aks_node_vm_size
  pods_cidr_block               = var.pods_cidr_block
  random_suffix                 = random_string.suffix.result
  resource_group_name           = azurerm_resource_group.this.name
  services_cidr_block           = var.services_cidr_block
  subnet_id                     = module.vpc.subnet_private_id
  tags                          = local.tags
}

module "kubernetes" {
  source         = "../../modules/kubernetes"
  enable_ingress = var.enable_ingress
  env            = var.env
  namespaces     = ["app1", "app2"]

  depends_on = [module.aks] # wait for the node pool, not just the endpoint
}
