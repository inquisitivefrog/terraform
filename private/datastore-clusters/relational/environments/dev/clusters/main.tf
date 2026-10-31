# The "tenant" side: a namespace asking the operators for two 3-node
# clusters, as an AWS account would ask RDS for two Aurora clusters.
resource "kubernetes_namespace_v1" "relational" {
  metadata {
    name = "relational"
  }
}

module "postgres" {
  source = "../../../modules/postgresql/cluster"

  name      = "pg"
  namespace = kubernetes_namespace_v1.relational.metadata[0].name
  instances = var.nodes
  image     = var.postgres_image
  database  = "appdb"
  owner     = "app"

  # Seconds before failing over a primary found unhealthy. Every second is
  # added to a real failure's write outage, after Kubernetes takes ~50 s to
  # notice a lost node: at 30 s a zone loss took 87 s, over the 60 s RTO
  # (2026-10-29). 5 s rides out a brief hiccup; a cold start of the whole
  # cluster may still fail over (2026-10-28: harmless, nothing lost).
  failover_delay = 5
  # A deleted primary pod first waits for its clients to disconnect, refusing
  # new connections. Pooled clients never disconnect, so it waited the whole
  # default 180 s and failover waited with it: new connections failed for
  # 184 s while the app's open ones kept writing (runbook 24, 2026-10-29).
  # 15 s, then a fast shutdown cuts the remaining sessions.
  smart_shutdown_timeout = 15

  parameters = {
    log_min_duration_statement = "2000" # ms; the slow-query log
    # Replicas tell the primary which row versions their queries still read,
    # so vacuum keeps them and replay never cancels a reader. Without it,
    # 150 requests/s of searches on the replicas lost 1,102 queries and ~500
    # connections to recovery conflicts (2026-10-27). Cost: the primary keeps
    # dead rows as long as the longest replica query (5 s statement_timeout).
    hot_standby_feedback = "on"
  }

  # WAL archived continuously; a full base backup each Sunday 03:00 UTC (the
  # runbooks take more on demand); 7 days restorable. Short: the laptop has
  # little disk. docs/BACKUPS.md.
  backup = {
    endpoint  = local.store.endpoint_in_cluster
    bucket    = local.store.buckets.pg
    secret    = "pg-backup-s3" # from scripts/backup_secrets.sh
    retention = "7d"
    schedule  = "0 0 3 * * 0"
  }
}

module "mysql" {
  source = "../../../modules/mysql/cluster"

  name           = "mysql"
  namespace      = kubernetes_namespace_v1.relational.metadata[0].name
  size           = var.nodes
  cr_version     = var.pxc_cr_version
  pxc_image      = var.pxc_image
  haproxy_image  = var.haproxy_image
  exporter_image = var.mysqld_exporter_image
  database       = "appdb"
  app_user       = "app"

  # mysqld needs the buffer pool plus about 760 MB (connections,
  # performance_schema, Galera). At 1536Mi the operator gave the pool half
  # (768M), leaving 0 headroom once the pool filled: pt-online-schema-change
  # filled it on every node and the writer was OOMKilled (2026-10-27; 768Mi
  # had already failed under a bulk seed). Pinned pool, 25% headroom.
  memory                  = "2Gi"
  innodb_buffer_pool_size = "768M"

  # Binlogs uploaded each minute; a full backup each Sunday 03:00 UTC (the
  # runbooks take more on demand); the last 2 scheduled ones kept.
  # docs/BACKUPS.md.
  backup = {
    endpoint = local.store.endpoint_in_cluster
    bucket   = local.store.buckets.mysql
    secret   = "mysql-backup-s3" # from scripts/backup_secrets.sh
    schedule = "0 3 * * 0"
    keep     = 2
    image    = var.xtrabackup_image
  }
}

locals {
  store = data.terraform_remote_state.backup_store.outputs
}
