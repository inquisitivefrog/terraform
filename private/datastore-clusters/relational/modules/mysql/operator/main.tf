# Percona Operator for MySQL (Percona XtraDB Cluster): the control plane for
# Galera-based MySQL clusters from a PerconaXtraDBCluster resource
# (../cluster), in any namespace.
resource "helm_release" "operator" {
  name             = "pxc-operator"
  repository       = "https://percona.github.io/percona-helm-charts/"
  chart            = "pxc-operator"
  version          = var.chart_version
  namespace        = "pxc-operator"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    watchAllNamespaces = true
    disableTelemetry   = true
    # The chart's default requests 20 Mi (the operator uses about 65 MiB) and
    # caps CPU at 200m. Request what it uses; no CPU limit (it would throttle
    # with CPU to spare); null removes the chart's.
    resources = {
      requests = { cpu = "50m", memory = "128Mi" }
      limits   = { cpu = null, memory = "512Mi" }
    }
  })]
}
