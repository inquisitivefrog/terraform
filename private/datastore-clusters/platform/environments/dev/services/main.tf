# Shared services every datastore category uses. Separate from ../cluster
# because the Helm provider needs the cluster's kubeconfig to exist at plan
# time. The backup store is outside the cluster (../backup-store).
module "monitoring" {
  source        = "../../../modules/monitoring"
  chart_version = var.kube_prometheus_stack_chart_version
}

module "cert_manager" {
  source        = "../../../modules/cert-manager"
  chart_version = var.cert_manager_chart_version
}
