# File 17: modules/cache/elasticache.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster
# https://registry.terraform.io/providers/hcavarsan/aws/latest/docs/resources/elasticache_subnet_group

resource "aws_elasticache_subnet_group" "private_only" {
  name       = "prod-private"
  subnet_ids = [var.vpc_subnet_private_id]
}

resource "aws_elasticache_cluster" "example" {
  cluster_id               = "redis-cluster-2"
  engine                   = "redis"
  node_type                = "cache.t3.micro" 
  num_cache_nodes          = 1
  parameter_group_name     = "default.redis6.x"
  engine_version           = "6.x"
  port                     = var.redis_port
  subnet_group_name        = aws_elasticache_subnet_group.private_only.name
  security_group_ids       = [var.sg_elasticache_id]
  snapshot_retention_limit = 7
  tags = {
    Name = "Redis 6.x"
  }
}

