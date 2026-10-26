output "namespace" {
  value = kubernetes_namespace_v1.relational.metadata[0].name
}

output "postgres" {
  value = {
    services   = module.postgres.services
    app_secret = module.postgres.app_secret
  }
}

output "mysql" {
  value = {
    services      = module.mysql.services
    system_secret = module.mysql.system_secret
  }
}
