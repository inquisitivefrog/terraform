# gcp/tfstate/environments variables

variable "employer" {
  type        = string
  default     = "ACME"
  description = "Employer Business Name"
}

variable "env" {
  type        = string
  default     = "develop"
  description = "Environment where resources are deployed"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  default     = "us-west1"
  description = "GCP region where resources are deployed"
}

variable "tfstate_bucket" {
  type        = string
  default     = ""
  description = "GCS bucket name prefix for terraform.tfstate"
}
