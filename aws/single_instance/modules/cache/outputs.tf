# File 22: modules/cache/output.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "elasticache_arn" {
  value = aws_elasticache_cluster.example.arn
}
