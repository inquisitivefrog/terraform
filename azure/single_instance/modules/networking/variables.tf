# modules/networking/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "my_laptop_cidr_block" {
  type        = string
  description = "Laptop public IP range"
}

variable "redis_port" {
  type        = number
  description = "Managed Redis port (10000, TLS)"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "subnet_apps_cidr_block" {
  type        = string
  description = "Container Apps subnet range"
}

variable "subnet_endpoints_cidr_block" {
  type        = string
  description = "Private endpoint subnet range"
}

variable "subnet_private_cidr_block" {
  type        = string
  description = "Private subnet range"
}

variable "subnet_public_cidr_block" {
  type        = string
  description = "Public subnet range"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VNet address range"
}
