# File 22: modules/cache/output.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "elasticache_arn" {
  value = aws_elasticache_replication_group.redis.arn
}

output "redis_primary_endpoint" {
  description = "Primary endpoint (TLS only)"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_auth_token" {
  description = "Redis AUTH token"
  value       = random_password.redis_auth.result
  sensitive   = true
}
