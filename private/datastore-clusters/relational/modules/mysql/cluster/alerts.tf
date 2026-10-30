# Alerts for this cluster (RUNBOOKS.md 1), from the mysqld_exporter sidecars
# (monitoring.tf) and the kubelet. The shared Prometheus loads every
# PrometheusRule (ruleSelector {}), and Alertmanager receives them.
# runbook_1_alerts.sh fires each tested one on purpose and clears it.
#   - Galera has no replication lag as such: a node that falls behind
#     queues write-sets to apply (wsrep_local_recv_queue), and flow control
#     slows the whole cluster unless the node is desynced.
#   - Not here: disk (local-path volumes report no usage; the node
#     filesystem rules of kube-prometheus-stack cover the shared disk),
#     certificate expiry (no metric) and backups (none configured yet).
locals {
  my_sel     = "namespace=\"${var.namespace}\",pod=~\"${var.name}-pxc-[0-9]+\""
  my_summary = "MySQL ${var.namespace}/${var.name}"
}

resource "kubernetes_manifest" "alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.name}-alerts"
      namespace = var.namespace
    }
    spec = {
      groups = [{
        name = "mysql-${var.name}"
        rules = [
          {
            # A node that is down, hung, or alive but evicted from the group
            alert = "MySQLMemberDown"
            expr = join(" ", [
              "(count(mysql_up{${local.my_sel}} == 1) or vector(0)) < ${var.size}",
              "or min(mysql_global_status_wsrep_cluster_size{${local.my_sel}}) < ${var.size}",
            ])
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.my_summary}: fewer than ${var.size} Galera members" }
          },
          {
            # 1 = Primary; anything else means this node lost quorum and
            # refuses queries
            alert       = "MySQLNotPrimary"
            expr        = "mysql_global_status_wsrep_cluster_status{${local.my_sel}} != 1"
            for         = "30s"
            labels      = { severity = "critical", cluster = var.name }
            annotations = { summary = "${local.my_summary}: {{ $labels.pod }} is not in the Primary Component" }
          },
          {
            # 4 = Synced; a joiner or donor passes through 1-3
            alert       = "MySQLNodeNotSynced"
            expr        = "mysql_global_status_wsrep_local_state{${local.my_sel}} != 4"
            for         = "5m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.my_summary}: {{ $labels.pod }} not Synced (state {{ $value }})" }
          },
          {
            alert       = "MySQLApplyQueue"
            expr        = "mysql_global_status_wsrep_local_recv_queue{${local.my_sel}} > 50"
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.my_summary}: {{ $labels.pod }} has {{ $value }} write-sets waiting to apply" }
          },
          {
            alert = "MySQLConnectionsHigh"
            expr = join(" ", [
              "max by (pod) (mysql_global_status_threads_connected{${local.my_sel}})",
              "/ on (pod) max by (pod) (mysql_global_variables_max_connections{${local.my_sel}}) > 0.8",
            ])
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.my_summary}: {{ $labels.pod }} at {{ $value | humanizePercentage }} of max_connections" }
          },
          {
            alert = "MySQLMemoryHigh"
            expr = join(" ", [
              "max by (pod) (container_memory_working_set_bytes{${local.my_sel},container=\"pxc\"})",
              "/ on (pod) max by (pod) (kube_pod_container_resource_limits{${local.my_sel},container=\"pxc\",resource=\"memory\"}) > 0.8",
            ])
            for         = "5m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.my_summary}: {{ $labels.pod }} at {{ $value | humanizePercentage }} of its memory limit" }
          },
        ]
      }]
    }
  }
}
