# modules/kms/variables.tf

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
  description = "GCP region; must match the bucket location for CMEK"
}
