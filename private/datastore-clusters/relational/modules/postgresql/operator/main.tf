# CloudNativePG: the control plane for PostgreSQL clusters (the part AWS runs
# for RDS). It creates, heals, fails over and upgrades a cluster from a
# Cluster resource (../cluster), in any namespace.
resource "helm_release" "operator" {
  name             = "cnpg"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = var.chart_version
  namespace        = "cnpg-system"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    config = { clusterWide = true }
    # The operator's own metrics, and CloudNativePG's official Grafana
    # dashboard as a ConfigMap labelled grafana_dashboard=1 (the chart's
    # default label, which Grafana's sidecar loads from any namespace).
    monitoring = {
      podMonitorEnabled = true
      grafanaDashboard  = { create = true }
    }
    # Without a request the operator is BestEffort: the first pod evicted
    # when its node runs short, and the clusters can't fail over without it.
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { memory = "256Mi" }
    }
  })]
}
