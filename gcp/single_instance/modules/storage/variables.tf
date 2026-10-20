# modules/storage/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "example_topic_id" {
  type        = string
  description = "Pub/Sub topic for bucket notifications"
}

variable "messages_key_id" {
  type        = string
  description = "KMS key for bucket encryption (AWS: sns_custom_key)"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for bucket name uniqueness"
}

variable "region" {
  type        = string
  description = "GCP region"
}
