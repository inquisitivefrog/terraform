output "releases" {
  value = [module.postgresql_operator.release, module.mysql_operator.release]
}
