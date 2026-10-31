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

# The Barman Cloud plugin: backups and WAL archiving to an S3-compatible
# store, through CloudNativePG's plugin interface (CNPG-I). It replaces the
# operator's built-in barmanObjectStore, deprecated and due for removal.
# Two parts: this Deployment, which the operator calls over mutual TLS
# (certificates from cert-manager, platform services) to add a sidecar to
# every instance pod; and that sidecar, which runs barman-cloud to ship WAL
# and take base backups. It must run in the operator's namespace.
# One copy (the chart supports only that): while it is down, existing
# instances keep archiving, but pods can't be created. See docs/BACKUPS.md.
resource "helm_release" "barman_cloud" {
  name       = "plugin-barman-cloud"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "plugin-barman-cloud"
  version    = var.barman_cloud_chart_version
  namespace  = helm_release.operator.namespace
  wait       = true

  values = [yamlencode({
    resources = {
      requests = { cpu = "20m", memory = "64Mi" }
      limits   = { memory = "256Mi" }
    }
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
