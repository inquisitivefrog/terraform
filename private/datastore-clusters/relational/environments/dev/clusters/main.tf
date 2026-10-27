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

  parameters = {
    log_min_duration_statement = "2000" # ms; the slow-query log
    # Replicas tell the primary which row versions their queries still read,
    # so vacuum keeps them and replay never cancels a reader. Without it,
    # 150 requests/s of searches on the replicas lost 1,102 queries and ~500
    # connections to recovery conflicts (2026-10-27). Cost: the primary keeps
    # dead rows as long as the longest replica query (5 s statement_timeout).
    hot_standby_feedback = "on"
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

  # 768Mi (the module default) left 80-150 MiB above the steady-state RSS
  # (610-690 MiB: the operator gives half to the buffer pool); a bulk seed
  # pushed one node past it and it was OOMKilled (2026-10-27). The operator
  # sizes the buffer pool from this, about half.
  memory = "1536Mi"
}
