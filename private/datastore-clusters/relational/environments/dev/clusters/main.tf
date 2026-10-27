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
}
