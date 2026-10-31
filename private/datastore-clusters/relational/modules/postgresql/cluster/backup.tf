# Backups to the S3-compatible store through the Barman Cloud plugin
# (installed with the operator). Off when var.backup is null.
#   - ObjectStore: where and how (bucket, endpoint, key Secret, compression,
#     retention). The cluster writes under s3://<bucket>/<cluster name>/:
#     base/ for base backups, wals/ for the WAL archive.
#   - The Cluster's plugins entry (main.tf) adds the plugin's sidecar to every
#     instance and makes it the WAL archiver: each finished WAL segment is
#     shipped as soon as PostgreSQL closes it (archive_timeout forces one at
#     least every 5 minutes; an idle database writes almost nothing).
#   - ScheduledBackup: a full base backup on a schedule, taken from a
#     replica when one is healthy. Runbooks take more on demand.
#   - Restore = the newest base backup before the target time, plus the WAL
#     after it, replayed up to that time (point-in-time recovery).
# See docs/BACKUPS.md.
resource "kubernetes_manifest" "object_store" {
  count = var.backup == null ? 0 : 1

  manifest = {
    apiVersion = "barmancloud.cnpg.io/v1"
    kind       = "ObjectStore"
    metadata = {
      name      = "${var.name}-backups"
      namespace = var.namespace
    }
    spec = {
      configuration = {
        destinationPath = "s3://${var.backup.bucket}/"
        endpointURL     = var.backup.endpoint
        s3Credentials = {
          accessKeyId     = { name = var.backup.secret, key = "ACCESS_KEY_ID" }
          secretAccessKey = { name = var.backup.secret, key = "ACCESS_SECRET_KEY" }
        }
        # Base backups: bzip2, the smallest (about 6:1), slower to restore
        # than gzip; the laptop is short of disk. WAL: zstd, fast and small.
        data = { compression = "bzip2" }
        wal  = { compression = "zstd" }
      }
      # A recovery window: keep what's needed to restore to any moment in the
      # last <n> days (the newest base backup older than that, and every one
      # since, with their WAL); delete the rest after the next backup.
      retentionPolicy = var.backup.retention
      instanceSidecarConfiguration = {
        resources = {
          requests = { cpu = "20m", memory = "128Mi" }
          limits   = { memory = "512Mi" }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "scheduled_backup" {
  count = var.backup == null ? 0 : 1

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "ScheduledBackup"
    metadata = {
      name      = "${var.name}-scheduled"
      namespace = var.namespace
    }
    spec = {
      cluster              = { name = var.name }
      schedule             = var.backup.schedule
      method               = "plugin"
      pluginConfiguration  = { name = local.barman_plugin }
      target               = "prefer-standby"
      backupOwnerReference = "self"
    }
  }

  depends_on = [kubernetes_manifest.cluster]
}

locals {
  barman_plugin = "barman-cloud.cloudnative-pg.io"
}
