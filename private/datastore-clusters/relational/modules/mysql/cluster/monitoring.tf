# Prometheus metrics for the cluster: a mysqld_exporter sidecar on every PXC
# node, a PodMonitor so the shared Prometheus scrapes it, and a Grafana
# dashboard (Galera membership and flow control, CRUDS load, slow queries
# and statements without an index, InnoDB memory).
#
# The exporter logs in as the operator's monitor user through mysqld's Unix
# socket, shared from the pod's tmp volume (read-only). A socket connection
# counts as secure transport, so require_secure_transport stays on without
# giving the exporter client certificates.

locals {
  exporter_sidecar = {
    name  = "mysqld-exporter"
    image = var.exporter_image
    args = [
      "--mysqld.address=unix:///var/run/mysqld/mysql.sock",
      "--mysqld.username=monitor",
      # Per-statement digests: time, rows examined, executions without an index.
      "--collect.perf_schema.eventsstatements",
      "--collect.info_schema.processlist",
    ]
    env = [{
      name      = "MYSQLD_EXPORTER_PASSWORD"
      valueFrom = { secretKeyRef = { name = "${var.name}-secrets", key = "monitor" } }
    }]
    ports        = [{ name = "metrics", containerPort = 9104 }]
    volumeMounts = [{ name = "tmp", mountPath = "/var/run/mysqld", readOnly = true }]
    resources = {
      requests = { cpu = "20m", memory = "32Mi" }
      limits   = { memory = "128Mi" }
    }
    securityContext = {
      allowPrivilegeEscalation = false
      readOnlyRootFilesystem   = true
      runAsNonRoot             = true
      capabilities             = { drop = ["ALL"] }
    }
  }
}

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
          "app.kubernetes.io/instance"  = var.name
          "app.kubernetes.io/component" = "pxc"
        }
      }
      podMetricsEndpoints = [{ port = "metrics", interval = "30s" }]
    }
  }
}

# Grafana's sidecar loads ConfigMaps labelled grafana_dashboard=1 from any
# namespace.
resource "kubernetes_config_map_v1" "dashboard" {
  metadata {
    name      = "${var.name}-grafana-dashboard"
    namespace = var.namespace
    labels    = { grafana_dashboard = "1" }
  }
  data = {
    "mysql-galera.json" = file("${path.module}/dashboards/mysql-galera.json")
  }
}
