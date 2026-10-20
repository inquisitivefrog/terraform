# modules/cache/outputs.tf

output "redis_hostname" {
  value = azurerm_managed_redis.this.hostname
}

output "redis_id" {
  value = azurerm_managed_redis.this.id
}

output "redis_port" {
  value = azurerm_managed_redis.this.default_database[0].port
}

output "redis_access_key" {
  value     = azurerm_managed_redis.this.default_database[0].primary_access_key
  sensitive = true
}
