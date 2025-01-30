# File 17: modules/cache/elasticache.tf
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster
# https://registry.terraform.io/providers/hcavarsan/aws/latest/docs/resources/elasticache_subnet_group

resource "aws_elasticache_subnet_group" "default" {
  name       = "prod"
  subnet_ids = [var.vpc_subnet_private_id, var.vpc_subnet_public_id]
}

resource "aws_elasticache_cluster" "example" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"  # Choose based on your performance requirements
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.x"
  port                 = var.redis_port
  subnet_group_name    = aws_elasticache_subnet_group.default.name
  security_group_ids   = [var.sg_elasticache_id]
  tags = {
    Name = "Redis 6.x"
  }
}

