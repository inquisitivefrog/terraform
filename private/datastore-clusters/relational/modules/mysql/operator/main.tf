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
    # Galera and HAProxy fail over without the operator, but recovering from
    # a lost quorum (autoRecovery), healing, backups and certificates need it.
    # Two copies in different zones, one leading; the chart's 60 s lease
    # would leave it leaderless for up to a minute, so CloudNativePG's 15 s.
    replicaCount  = 2
    affinity      = local.one_per_zone
    leaseDuration = "15s"
    renewDeadline = "10s"
    retryPeriod   = "2s"
  })]
}

locals {
  one_per_zone = {
    podAntiAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = [{
        topologyKey   = "topology.kubernetes.io/zone"
        labelSelector = { matchLabels = { "app.kubernetes.io/name" = "pxc-operator" } }
      }]
    }
  }
}
