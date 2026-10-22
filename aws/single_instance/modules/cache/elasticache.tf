# File 17: modules/cache/elasticache.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group
#
# A one-node replication group rather than aws_elasticache_cluster: for
# Redis, in-transit encryption (TLS) and AUTH are only available on
# replication groups. Clients connect with TLS and the token, e.g.
#   REDISCLI_AUTH=<token> redis-cli -h <primary endpoint> -p 6379 --tls PING

resource "aws_elasticache_subnet_group" "private_only" {
  name       = "prod-private"
  subnet_ids = [var.vpc_subnet_private_id]
}

# AUTH allows 16-128 printable characters except @, " and /; alphanumeric
# avoids escaping problems in redis-cli and connection strings.
resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "redis-single-instance"
  description          = "single_instance Redis, TLS and AUTH required"
  engine               = "redis"
  engine_version       = "7.1"
  # tflint-ignore: aws_elasticache_replication_group_default_parameter_group # defaults are fine; nothing to tune
  parameter_group_name       = "default.redis7"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 1
  automatic_failover_enabled = false # needs at least 2 nodes
  multi_az_enabled           = false
  port                       = var.redis_port
  subnet_group_name          = aws_elasticache_subnet_group.private_only.name
  security_group_ids         = [var.sg_elasticache_id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result
  snapshot_retention_limit   = 7
  tags = {
    Name = "Redis 7.1"
  }
}
