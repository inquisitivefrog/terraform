# modules/messages/variables.tf

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure region (the storage account's)"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the topic"
}

variable "storage_account_id" {
  type        = string
  description = "Storage account whose blob events the topic publishes"
}
