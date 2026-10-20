# modules/vpc/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "flow_log_storage_account_id" {
  type        = string
  description = "Storage account that receives VNet flow logs"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VNet address range"
}
