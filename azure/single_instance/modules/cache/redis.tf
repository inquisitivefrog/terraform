# modules/cache/redis.tf
# Azure counterpart of aws/single_instance/modules/cache/elasticache.tf
# Azure Managed Redis (the classic Azure Cache for Redis is being retired;
# grid-meter-app uses this too). Single node, TLS only (port 10000), access
# key auth (the AWS open item had no AUTH), reached through a private
# endpoint with public access off.
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/managed_redis

resource "azurerm_managed_redis" "this" {
  name                      = "redis-bluedragon-${var.env}-${var.random_suffix}" # global DNS name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  sku_name                  = var.sku_name
  high_availability_enabled = false
  public_network_access     = "Disabled"

  default_database {
    access_keys_authentication_enabled = true
    client_protocol                    = "Encrypted"
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                = "redis-${var.env}"
  private_dns_zone_id = azurerm_private_dns_zone.redis.id
  virtual_network_id  = var.vnet_id
}

resource "azurerm_private_endpoint" "redis" {
  name                = "pe-redis-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_endpoints_id
  tags                = var.tags

  private_service_connection {
    name                           = "redis"
    private_connection_resource_id = azurerm_managed_redis.this.id
    subresource_names              = ["redisEnterprise"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "redis"
    private_dns_zone_ids = [azurerm_private_dns_zone.redis.id]
  }
}
