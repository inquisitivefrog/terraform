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
    # The operator, not the instances, decides a failover: one copy in the
    # zone that fails means no failover until Kubernetes evicts it (300 s;
    # runbook 26, 2026-10-30). Two copies in different zones, one leading
    # (15 s lease): the other takes over when its zone goes.
    replicaCount = 2
    affinity     = local.one_per_zone
  })]
}

locals {
  one_per_zone = {
    podAntiAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = [{
        topologyKey   = "topology.kubernetes.io/zone"
        labelSelector = { matchLabels = { "app.kubernetes.io/name" = "cloudnative-pg" } }
      }]
    }
  }
}
