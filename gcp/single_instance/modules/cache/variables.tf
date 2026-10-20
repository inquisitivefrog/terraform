# modules/cache/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "redis_cidr_block" {
  type        = string
  description = "/29 reserved for Memorystore; must not overlap a subnet"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "Zone for the Basic-tier instance"
}
