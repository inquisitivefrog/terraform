# modules/vpc/vnet.tf
# Azure counterpart of aws/single_instance/modules/vpc (and gcp's)
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

# One Network Watcher per region per subscription. Azure creates one in
# NetworkWatcherRG when the first VNet appears; creating ours first (the
# VNet depends on it) keeps it in this resource group and in Terraform.
resource "azurerm_network_watcher" "this" {
  name                = "nw-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-main-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vpc_cidr_block]
  tags                = var.tags

  depends_on = [azurerm_network_watcher.this]
}

# Same /24 offsets as AWS and GCP: public .3, private .4. Azure subnets span
# the region, so one private subnet holds the private VM and the AKS nodes.
resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vpc_cidr_block, 8, 3)]
}

resource "azurerm_subnet" "private" {
  name                            = "private"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = [cidrsubnet(var.vpc_cidr_block, 8, 4)]
  default_outbound_access_enabled = false # egress only through the NAT gateway
}

# Private endpoints (Memorystore's role here: Azure Managed Redis)
resource "azurerm_subnet" "endpoints" {
  name                 = "endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vpc_cidr_block, 8, 5)]
}

# Container Apps environment (workload profiles need at least a /27)
resource "azurerm_subnet" "apps" {
  name                            = "apps"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = [cidrsubnet(var.vpc_cidr_block, 11, 48)] # x.x.6.0/27
  default_outbound_access_enabled = false

  delegation {
    name = "container-apps"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# NAT gateway: outbound for the private and apps subnets (AWS: NAT gateway + EIP)
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                = "nat-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "apps" {
  subnet_id      = azurerm_subnet.apps.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# VNet flow logs to the logs storage account (AWS: flow logs to CloudWatch).
# Retention is the logs account's own 365-day lifecycle rule: a flow-log
# retention policy makes Azure add a rule to that account's lifecycle policy,
# which Terraform then fights on every apply.
resource "azurerm_network_watcher_flow_log" "vnet" {
  name                 = "flowlog-vnet-${var.env}"
  network_watcher_name = azurerm_network_watcher.this.name
  resource_group_name  = var.resource_group_name
  target_resource_id   = azurerm_virtual_network.main.id
  storage_account_id   = var.flow_log_storage_account_id
  enabled              = true
  version              = 2

  retention_policy {
    enabled = false
    days    = 0
  }
}
