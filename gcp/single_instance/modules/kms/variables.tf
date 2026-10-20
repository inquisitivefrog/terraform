# modules/kms/variables.tf

variable "admin_sa_email" {
  type        = string
  description = "Admin service account, administers the example keys"
}

variable "developer_sa_email" {
  type        = string
  description = "Developer service account, may sign with the asymmetric key"
}

variable "env" {
  type        = string
  description = "environment: prod, dev"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for key ring name uniqueness"
}

variable "region" {
  type        = string
  description = "GCP region; must match bucket and cluster locations for CMEK"
}
