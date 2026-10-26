# Deliberately not the newest: the clusters start on older, still-deployed
# versions so the runbooks can patch them (minor) and then upgrade them (major).
# Path: PostgreSQL 16.13 -> 16.15 (patch) -> 18 (major, pg_upgrade in place;
# images must stay on the same Debian release, trixie).
variable "postgres_image" {
  description = "CloudNativePG operand image; the operator's own default is 18.6"
  type        = string
  default     = "ghcr.io/cloudnative-pg/postgresql:16.13-standard-trixie"
}

variable "pxc_cr_version" {
  description = "Must match the operator version installed by ../operators"
  type        = string
  default     = "1.20.0"
}

# Path: PXC 8.0.44 -> 8.0.45 (patch; the operator 1.20.0 tested 8.0) -> 8.4.8
# (major). MySQL 8.0 reached upstream end of life in April 2026: the
# "hurry and upgrade" situation, on purpose.
variable "pxc_image" {
  description = "Percona XtraDB Cluster image; the operator 1.20.0 default is 8.4.8-8.1"
  type        = string
  default     = "percona/percona-xtradb-cluster:8.0.44-35.1"
}

variable "haproxy_image" {
  type    = string
  default = "percona/haproxy:2.8.18-1"
}

variable "nodes" {
  description = "Nodes per cluster, one per zone"
  type        = number
  default     = 3
}
