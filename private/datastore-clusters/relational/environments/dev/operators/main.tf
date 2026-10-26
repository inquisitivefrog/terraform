# Relational operators. Separate from ../clusters because the clusters are
# custom resources: Terraform can plan them only once these CRDs exist.
module "postgresql_operator" {
  source        = "../../../modules/postgresql/operator"
  chart_version = var.cnpg_chart_version
}

module "mysql_operator" {
  source        = "../../../modules/mysql/operator"
  chart_version = var.pxc_operator_chart_version
}
