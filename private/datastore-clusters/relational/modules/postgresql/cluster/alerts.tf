# Alerts for this cluster (RUNBOOKS.md 1), from the instances' exporter
# metrics (monitoring.tf) and the kubelet. The shared Prometheus loads every
# PrometheusRule (ruleSelector {}), and Alertmanager receives them.
# runbook_1_alerts.sh fires each tested one on purpose and clears it.
#   - "for" rides out what heals by itself: a failover takes ~17 s
#     (runbook 24), a pod restart under a minute.
#   - Not here: disk (local-path volumes report no usage; the node
#     filesystem rules of kube-prometheus-stack cover the shared disk),
#     certificate expiry (no metric; CloudNativePG renews its own) and
#     backups (none configured yet).
locals {
  pg_sel     = "namespace=\"${var.namespace}\",pod=~\"${var.name}-[0-9]+\""
  pg_summary = "PostgreSQL ${var.namespace}/${var.name}"
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
        rules = [
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
        ]
      }]
    }
  }
}
