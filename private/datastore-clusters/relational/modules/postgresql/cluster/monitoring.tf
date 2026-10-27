# Prometheus scrapes every instance's built-in exporter (port "metrics",
# 9187): replication lag, WAL, checkpoints, connections, locks, database
# size. CloudNativePG's own spec.monitoring.enablePodMonitor is deprecated
# in favour of a PodMonitor like this one. The dashboard ships with the
# operator (../operator).
resource "kubernetes_manifest" "pod_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"
    metadata = {
      name      = var.name
      namespace = var.namespace
    }
    spec = {
      selector = {
        matchLabels = {
          "cnpg.io/cluster" = var.name
          "cnpg.io/podRole" = "instance"
        }
      }
      podMetricsEndpoints = [{ port = "metrics", interval = "30s" }]
    }
  }
}
