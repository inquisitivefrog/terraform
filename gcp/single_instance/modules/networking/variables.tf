# modules/networking/variables.tf

variable "env" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
}

variable "gke_node_tag" {
  type        = string
  description = "Network tag on GKE nodes"
}

variable "my_laptop_cidr_block" {
  type        = string
  description = "Laptop public IP range for SSH and HTTP(S)"
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
  description = "Memorystore reserved IP range"
}

variable "redis_port" {
  type        = number
  default     = 6379
  description = "Redis port"
}

variable "subnet_private_cidr_block" {
  type        = string
  description = "Private subnet range"
}

variable "subnet_public_cidr_block" {
  type        = string
  description = "Public subnet range"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC address range"
}
