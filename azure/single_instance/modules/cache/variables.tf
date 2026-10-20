# modules/cache/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for the cache's global name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "sku_name" {
  type        = string
  default     = "Balanced_B0"
  description = "Managed Redis SKU (smallest: Balanced_B0)"
}

variable "subnet_endpoints_id" {
  type        = string
  description = "Subnet for the private endpoint"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vnet_id" {
  type        = string
  description = "VNet linked to the private DNS zone"
}
