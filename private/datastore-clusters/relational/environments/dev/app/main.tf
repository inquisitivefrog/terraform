# Root 3: the orders example app, once per engine, plus what the load test
# needs in the cluster (its k6 script) and the dashboard that shows it.
# scripts/load_test.sh runs the k6 Job itself: a test run is an action, not
# infrastructure.

locals {
  namespace = data.terraform_remote_state.clusters.outputs.namespace
  pg        = data.terraform_remote_state.clusters.outputs.postgres
  mysql     = data.terraform_remote_state.clusters.outputs.mysql
}

module "orders_pg" {
  source = "../../../modules/orders-app"

  name        = "orders-pg"
  namespace   = local.namespace
  engine      = "postgresql"
  image       = var.app_image
  replicas    = var.replicas
  writer_host = local.pg.services.read_write
  reader_host = local.pg.services.read_only
  database    = "appdb"
  # The database owner CloudNativePG created; not a superuser.
  user            = "app"
  password_secret = { name = local.pg.app_secret, key = "password" }
  ca_secret       = "pg-ca"
}

module "orders_mysql" {
  source = "../../../modules/orders-app"

  name        = "orders-mysql"
  namespace   = local.namespace
  engine      = "mysql"
  image       = var.app_image
  replicas    = var.replicas
  writer_host = local.mysql.services.writer
  reader_host = local.mysql.services.readers
  database    = "appdb"
  # The user the Percona operator created from spec.users: all privileges
  # on appdb only.
  user            = "app"
  password_secret = { name = "mysql-custom-user-secret", key = "app" }
  # mysqld presents the operator's internal certificate to clients too
  # (@@ssl_cert = /etc/mysql/ssl-internal/tls.crt), and the CAs in
  # mysql-ssl and mysql-ssl-internal are different roots: trusting
  # mysql-ssl fails with "signature check failed".
  ca_secret = "mysql-ssl-internal"
}

resource "kubernetes_config_map_v1" "k6_script" {
  metadata {
    name      = "orders-k6"
    namespace = local.namespace
  }
  data = {
    "orders.js" = file("${path.module}/../../../app/k6/orders.js")
  }
}

resource "kubernetes_config_map_v1" "dashboard" {
  metadata {
    name      = "orders-grafana-dashboard"
    namespace = local.namespace
    labels    = { grafana_dashboard = "1" }
  }
  data = {
    "orders-load.json" = file("${path.module}/../../../app/dashboards/orders-load.json")
  }
}
