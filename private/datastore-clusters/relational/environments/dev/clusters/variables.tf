# Deliberately not the newest: the clusters start on older, still-deployed
# versions so the runbooks can patch them (minor) and then upgrade them (major).
# Path: PostgreSQL 16.13 -> 16.15 (patch, runbook 13) -> 18 (major, pg_upgrade
# in place; images must stay on the same Debian release, trixie).
variable "postgres_image" {
  description = "CloudNativePG operand image; the operator's own default is 18.6"
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:16.15-standard-trixie"
}

variable "pxc_cr_version" {
  description = "Must match the operator version installed by ../operators"
  type        = string
  default     = "1.20.0"
}

# Path: PXC 8.0.44 -> 8.0.46 (patch, runbook 13: the newest 8.0, 2026-07-23;
# MySQL 8.0 cannot go back a minor) -> 8.4.8 (major). MySQL 8.0 reached
# upstream end of life in April 2026: the "hurry and upgrade" situation, on
# purpose.
variable "pxc_image" {
  description = "Percona XtraDB Cluster image; the operator 1.20.0 default is 8.4.8-8.1"
  type        = string
  default     = "percona/percona-xtradb-cluster:8.0.46-38.1"
}

variable "haproxy_image" {
  type    = string
  default = "percona/haproxy:2.8.18-1"
}

# v0.21.0 (2026-10-22) is days old; pinned to the release before it.
variable "mysqld_exporter_image" {
  description = "Prometheus exporter sidecar on each PXC node"
  type        = string
  default     = "prom/mysqld-exporter:v0.20.0-distroless"
}

variable "nodes" {
  description = "Nodes per cluster, one per zone"
  type        = number
  default     = 3
}
