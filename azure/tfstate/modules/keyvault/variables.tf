# modules/keyvault/variables.tf

variable "env" {
  type        = string
  description = "environment: prod, dev"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for vault name uniqueness"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the vault and identity"
}
