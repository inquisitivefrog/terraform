# modules/cache/memorystore.tf
# GCP counterpart of aws/single_instance/modules/cache/elasticache.tf
# Redis 7.2 with AUTH and in-transit TLS: the AWS cluster's open item
# (Redis 6.2, no TLS or AUTH) is fixed here rather than carried over.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/redis_instance

resource "google_redis_instance" "main" {
  name               = "redis-${var.env}"
  project            = var.project_id
  region             = var.region
  location_id        = var.zone
  tier               = "BASIC"
  memory_size_gb     = 1
  redis_version      = "REDIS_7_2"
  authorized_network = var.network_id
  connect_mode       = "DIRECT_PEERING"
  reserved_ip_range  = var.redis_cidr_block

  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  # Daily RDB snapshots (AWS: snapshot_retention_limit = 7)
  persistence_config {
    persistence_mode    = "RDB"
    rdb_snapshot_period = "TWENTY_FOUR_HOURS"
  }

  labels = {
    environment = var.env
  }
}
