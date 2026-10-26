# Shared services every datastore category uses. Separate from ../cluster
# because the Helm provider needs the cluster's kubeconfig to exist at plan
# time. Later: cert-manager and the S3-compatible object store for backups.
module "monitoring" {
  source        = "../../../modules/monitoring"
  chart_version = var.kube_prometheus_stack_chart_version
}
