# modules/messages/variables.tf

variable "environment" {
  description = "The environment this topic is deployed to"
  type        = string
}

variable "gcs_service_agent" {
  description = "Cloud Storage service agent email, granted publish on the topic"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pubsub_logging_key_id" {
  type        = string
  description = "ID of the KMS key for Pub/Sub encryption"
}

variable "region" {
  type        = string
  description = "GCP region where messages are stored"
}
