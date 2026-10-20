# modules/compute/variables.tf

variable "cloudrun_sa_email" {
  type        = string
  description = "Cloud Run runtime service account"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "machine_type" {
  type        = string
  description = "VM machine type"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "private_vm_tag" {
  type        = string
  description = "Network tag for the private VM"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "public_vm_tag" {
  type        = string
  description = "Network tag for the public VM"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "subnet_private_id" {
  type        = string
  description = "Private subnet ID"
}

variable "subnet_public_id" {
  type        = string
  description = "Public subnet ID"
}

variable "vm_sa_email" {
  type        = string
  description = "VM service account (AWS: EC2 instance profile)"
}

variable "zone" {
  type        = string
  description = "Zone for the VMs"
}
