# modules/identity/variables.tf

variable "cloud_run_service_name" {
  type        = string
  description = "Cloud Run service the admin manages"
}

variable "dev_bucket_name" {
  type        = string
  description = "Developer bucket"
}

variable "env" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
}

variable "key_ring_id" {
  type        = string
  description = "KMS key ring the admin manages"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "vm_names" {
  type        = list(string)
  description = "VM names for resource-level grants"
}

variable "zone" {
  type        = string
  description = "Zone of the VMs"
}
