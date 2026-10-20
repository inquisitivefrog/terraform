# modules/vpc/variables.tf

variable "env" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
}

variable "pods_cidr_block" {
  type        = string
  description = "GKE pod secondary range"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "services_cidr_block" {
  type        = string
  description = "GKE service secondary range"
}

variable "vpc_cidr_block" {
  type        = string
  description = "IPv4 address range"
}
