# Alerts for this cluster (RUNBOOKS.md 1), from the instances' exporter
# metrics (monitoring.tf) and the kubelet. The shared Prometheus loads every
# PrometheusRule (ruleSelector {}), and Alertmanager receives them.
# runbook_1_alerts.sh fires each tested one on purpose and clears it.
#   - "for" rides out what heals by itself: a failover takes ~17 s
#     (runbook 24), a pod restart under a minute.
#   - Not here: disk (local-path volumes report no usage; the node
#     filesystem rules of kube-prometheus-stack cover the shared disk),
#     certificate expiry (no metric; CloudNativePG renews its own).
#   - Backups (when var.backup is set): the Barman Cloud plugin's metrics on
#     every instance (the store as the plugin last saw it), and the
#     primary's archiver for WAL.
locals {
  pg_sel     = "namespace=\"${var.namespace}\",pod=~\"${var.name}-[0-9]+\""
  pg_summary = "PostgreSQL ${var.namespace}/${var.name}"
}

locals {
  barman_metric = "barman_cloud_cloudnative_pg_io"
  # A list (not a tuple), so the empty and full branches have one type.
  # namespace as a label: max() drops it, and Alertmanager groups by it
  # (2026-11-04: these alerts came through with none).
  pg_backup_rules = var.backup == null ? [] : tolist([
    {
      # The newest complete base backup in the store, or none at all
      alert = "PostgreSQLBackupTooOld"
      expr = join(" ", [
        "time() - max(${local.barman_metric}_last_available_backup_timestamp{${local.pg_sel}}) > ${var.backup.alert_after_hours * 3600}",
        "or absent(${local.barman_metric}_last_available_backup_timestamp{${local.pg_sel}})",
      ])
      for         = "10m"
      labels      = { severity = "warning", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.pg_summary}: no base backup in the store newer than ${var.backup.alert_after_hours} h" }
    },
    {
      # The newest attempt failed (earlier good backups still count above)
      alert       = "PostgreSQLBackupFailed"
      expr        = "max(${local.barman_metric}_last_failed_backup_timestamp{${local.pg_sel}}) > max(${local.barman_metric}_last_available_backup_timestamp{${local.pg_sel}})"
      for         = "1m"
      labels      = { severity = "warning", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.pg_summary}: the newest base backup attempt failed (kubectl -n ${var.namespace} get backups.postgresql.cnpg.io)" }
    },
    {
      # The primary's last archive attempt failed: WAL piles up in pg_wal
      # and point-in-time recovery stops at the last archived segment
      alert = "PostgreSQLWALArchiveFailing"
      expr = join(" ", [
        "max by (pod) (cnpg_pg_stat_archiver_last_failed_time{${local.pg_sel}}) > max by (pod) (cnpg_pg_stat_archiver_last_archived_time{${local.pg_sel}})",
        "and on (pod) max by (pod) (cnpg_pg_replication_in_recovery{${local.pg_sel}}) == 0",
      ])
      for         = "5m"
      labels      = { severity = "critical", cluster = var.name, namespace = var.namespace }
      annotations = { summary = "${local.pg_summary}: WAL archiving failing on {{ $labels.pod }}" }
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
        name = "postgresql-${var.name}"
        rules = concat([
          {
            # Instances whose PostgreSQL answers the exporter's queries.
            # Not cnpg_collector_up: it stayed 1 for an instance fenced
            # (PostgreSQL stopped) for 5 minutes (runbook 1, 2026-10-30).
            alert       = "PostgreSQLInstanceDown"
            expr        = "(count(cnpg_pg_replication_in_recovery{${local.pg_sel}}) or vector(0)) < ${var.instances}"
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $value }} of ${var.instances} instances up" }
          },
          {
            # None during a failover that did not finish; two is split brain
            alert       = "PostgreSQLPrimaryCount"
            expr        = "(count(cnpg_pg_replication_in_recovery{${local.pg_sel}} == 0) or vector(0)) != 1"
            for         = "1m"
            labels      = { severity = "critical", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $value }} primaries (want 1)" }
          },
          {
            alert       = "PostgreSQLReplicasNotStreaming"
            expr        = "max(cnpg_pg_replication_streaming_replicas{${local.pg_sel}}) < ${var.instances - 1}"
            for         = "2m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $value }} of ${var.instances - 1} replicas streaming" }
          },
          {
            # Seconds since the last replayed transaction while WAL waits
            # (0 when replay is caught up, even with no writes)
            alert       = "PostgreSQLReplicationLag"
            expr        = "max by (pod) (cnpg_pg_replication_lag{${local.pg_sel}}) > 30"
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $labels.pod }} replay {{ $value }} s behind" }
          },
          {
            alert = "PostgreSQLConnectionsHigh"
            expr = join(" ", [
              "sum by (pod) (cnpg_backends_total{${local.pg_sel}})",
              "/ on (pod) max by (pod) (cnpg_pg_settings_setting{${local.pg_sel},name=\"max_connections\"}) > 0.8",
            ])
            for         = "1m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $labels.pod }} at {{ $value | humanizePercentage }} of max_connections" }
          },
          {
            alert = "PostgreSQLMemoryHigh"
            expr = join(" ", [
              "max by (pod) (container_memory_working_set_bytes{${local.pg_sel},container=\"postgres\"})",
              "/ on (pod) max by (pod) (kube_pod_container_resource_limits{${local.pg_sel},container=\"postgres\",resource=\"memory\"}) > 0.8",
            ])
            for         = "5m"
            labels      = { severity = "warning", cluster = var.name }
            annotations = { summary = "${local.pg_summary}: {{ $labels.pod }} at {{ $value | humanizePercentage }} of its memory limit" }
          },
        ], local.pg_backup_rules)
      }]
    }
  }
}
