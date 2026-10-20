# modules/storage/variables.tf

variable "employer" {
  description = "Employer that owns environment deployed"
  type        = string
}

variable "enable_notifications" {
  type        = bool
  default     = false
  description = "Enable bucket notifications to Pub/Sub"
}

variable "env" {
  default     = "develop"
  description = "Environment where resources are deployed"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pubsub_topic_logging_id" {
  default     = ""
  description = "ID of the Pub/Sub topic for bucket notifications"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for bucket name uniqueness"
  type        = string
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "state_bucket_key_id" {
  description = "ID of the state bucket KMS key; null uses Google-managed encryption (bootstrap)"
  type        = string
  default     = null
}

variable "tfstate_bucket" {
  description = "GCS bucket name for storage of terraform.tfstate file"
  type        = string
}
