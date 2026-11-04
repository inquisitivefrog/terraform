# Alerts for this cluster (RUNBOOKS.md 1), from the mysqld_exporter sidecars
# (monitoring.tf) and the kubelet. The shared Prometheus loads every
# PrometheusRule (ruleSelector {}), and Alertmanager receives them.
# runbook_1_alerts.sh fires each tested one on purpose and clears it.
#   - Galera has no replication lag as such: a node that falls behind
#     queues write-sets to apply (wsrep_local_recv_queue), and flow control
#     slows the whole cluster unless the node is desynced.
#   - Not here: disk (local-path volumes report no usage; the node
#     filesystem rules of kube-prometheus-stack cover the shared disk),
#     certificate expiry (no metric).
#   - Backups (when var.backup is set): PXC backup resources as metrics
#     from kube-state-metrics (pxc_backup_*, platform monitoring module),
#     and the binlog collector's Deployment and container.
locals {
  my_sel     = "namespace=\"${var.namespace}\",pod=~\"${var.name}-pxc-[0-9]+\""
  my_summary = "MySQL ${var.namespace}/${var.name}"
}

locals {
  my_backup_sel = "namespace=\"${var.namespace}\",cluster=\"${var.name}\""
  my_pitr_sel   = "namespace=\"${var.namespace}\",pod=~\"${var.name}-pitr-.+\",container=\"pitr\""
  # A list (not a tuple), so the empty and full branches have one type.
  # namespace as a label: max() drops it, and Alertmanager groups by it
  # (2026-11-04: these alerts came through with none).
  my_backup_rules = var.backup == null ? [] : tolist([
    {
      # The newest successful full backup, scheduled or by hand, or none
      alert = "MySQLBackupTooOld"
      expr = join(" ", [
        "time() - max(pxc_backup_completed_timestamp_seconds{${local.my_backup_sel},state=\"Succeeded\"}) > ${var.backup.alert_after_hours * 3600}",
        "or absent(pxc_backup_completed_timestamp_seconds{${local.my_backup_sel},state=\"Succeeded\"})",
      ])
      for         = "10m"
      labels      = { severity = "warning", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.my_summary}: no successful full backup newer than ${var.backup.alert_after_hours} h" }
    },
    {
      # A backup failed after the newest success
      alert = "MySQLBackupFailed"
      expr = join(" ", [
        "max(pxc_backup_created_timestamp_seconds{${local.my_backup_sel},state=~\"Failed|Error\"})",
        "> max(pxc_backup_completed_timestamp_seconds{${local.my_backup_sel},state=\"Succeeded\"})",
      ])
      for         = "1m"
      labels      = { severity = "warning", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.my_summary}: the newest full backup failed (kubectl -n ${var.namespace} get perconaxtradbclusterbackups)" }
    },
    {
      # No binlogs uploaded: point-in-time recovery stops at the last one.
      # 5 minutes: after a restart it exits until MySQL is up (2026-11-04).
      alert       = "MySQLBinlogCollectorDown"
      expr        = "(max(kube_deployment_status_replicas_available{namespace=\"${var.namespace}\",deployment=\"${var.name}-pitr\"}) or vector(0)) < 1"
      for         = "5m"
      labels      = { severity = "critical", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.my_summary}: binlog collector down; binlogs not uploaded" }
    },
    {
      # Killed for memory in the last 30 minutes: each upload holds a
      # 528 MiB buffer (docs/BACKUPS.md); the limit may be too low
      alert = "MySQLBinlogCollectorOOMKilled"
      expr = join(" ", [
        "increase(kube_pod_container_status_restarts_total{${local.my_pitr_sel}}[30m]) > 0",
        "and on (pod, container) kube_pod_container_status_last_terminated_reason{${local.my_pitr_sel},reason=\"OOMKilled\"} == 1",
      ])
      for         = "0s"
      labels      = { severity = "warning", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.my_summary}: binlog collector {{ $labels.pod }} OOMKilled; raise its memory limit" }
    },
  ])
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
        rules = concat([
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
        ], local.my_backup_rules)
      }]
    }
  }
}
