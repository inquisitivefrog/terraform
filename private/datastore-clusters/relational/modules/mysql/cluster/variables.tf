variable "name" {
  description = "Cluster name; pods <name>-pxc-N, services <name>-haproxy (writes) and <name>-haproxy-replicas (reads)"
  type        = string
}

variable "namespace" {
  description = "Namespace the cluster runs in"
  type        = string
}

variable "size" {
  description = "Galera nodes, one per zone; a majority (2 of 3) must agree to commit"
  type        = number
  default     = 3

  validation {
    condition     = var.size >= 3 && var.size % 2 == 1
    error_message = "Use an odd number of at least three nodes: Galera needs a strict majority to stay writable."
  }
}

variable "cr_version" {
  description = "spec.crVersion: the operator version whose defaults this cluster follows"
  type        = string
}

variable "pxc_image" {
  description = "percona/percona-xtradb-cluster image"
  type        = string
}

variable "haproxy_image" {
  description = "percona/haproxy image"
  type        = string
}

variable "database" {
  description = "Application database the operator creates for the application user"
  type        = string
}

variable "app_user" {
  description = "Application user with all privileges on database; the operator generates its password"
  type        = string
}

variable "storage_size" {
  description = "Volume per node"
  type        = string
  default     = "2Gi"
}

variable "cpu_request" {
  type    = string
  default = "250m"
}

variable "memory" {
  description = "Memory request and limit per node; unless innodb_buffer_pool_size is set, the operator sizes the buffer pool from it (about half)"
  type        = string
  default     = "768Mi"
}

variable "innodb_buffer_pool_size" {
  description = "InnoDB buffer pool size (e.g. \"768M\"); null lets the operator choose. Leave memory for the rest of mysqld: about 760 MB measured with 3 nodes and the orders app"
  type        = string
  default     = null
}

variable "exporter_image" {
  description = "prom/mysqld-exporter image for the metrics sidecar"
  type        = string
}

variable "wait_timeout" {
  description = "How long apply waits for the cluster to report ready"
  type        = string
  default     = "20m"
}
