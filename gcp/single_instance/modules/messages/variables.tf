# modules/messages/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "gcs_service_agent" {
  type        = string
  description = "Cloud Storage service agent email, granted publish on example topic"
}

variable "messages_key_id" {
  type        = string
  description = "KMS key for topic encryption"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region where messages are stored"
}
