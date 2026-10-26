variable "name" {
  description = "Cluster name; services are <name>-rw (primary), <name>-ro (replicas), <name>-r (any)"
  type        = string
}

variable "namespace" {
  description = "Namespace the cluster runs in"
  type        = string
}

variable "instances" {
  description = "PostgreSQL instances: one primary, the rest streaming replicas, one per zone"
  type        = number
  default     = 3

  validation {
    condition     = var.instances >= 3
    error_message = "Use at least three instances so a synchronous replica survives losing one zone."
  }
}

variable "image" {
  description = "CloudNativePG operand image (ghcr.io/cloudnative-pg/postgresql:<version>-standard-<distro>)"
  type        = string
}

variable "database" {
  description = "Application database, created at bootstrap"
  type        = string
}

variable "owner" {
  description = "Application role owning the database; its password is in the <name>-app secret"
  type        = string
}

variable "storage_size" {
  description = "Volume per instance"
  type        = string
  default     = "2Gi"
}

variable "cpu_request" {
  type    = string
  default = "250m"
}

variable "memory" {
  description = "Memory request and limit per instance (equal: Guaranteed-style memory, no OOM surprises from overcommit)"
  type        = string
  default     = "512Mi"
}

variable "synchronous_replicas" {
  description = "Standbys that must confirm each commit (ANY n quorum). 1 of 2 standbys: a commit survives losing any one zone"
  type        = number
  default     = 1
}

variable "parameters" {
  description = "postgresql.conf parameters"
  type        = map(string)
  default     = {}
}

variable "wait_timeout" {
  description = "How long apply waits for the cluster to report Ready"
  type        = string
  default     = "15m"
}
