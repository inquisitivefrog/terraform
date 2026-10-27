output "urls" {
  description = "In-cluster base URLs of the app, one per engine"
  value = {
    postgresql = module.orders_pg.url
    mysql      = module.orders_mysql.url
  }
}

output "dashboard" {
  value = "Relational / Orders load (k6 and app)"
}
