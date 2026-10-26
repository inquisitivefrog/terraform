output "prometheus_remote_write_url" {
  value = module.monitoring.prometheus_remote_write_url
}

output "grafana" {
  value = module.monitoring.grafana
}
