# modules/messages/variables.tf

variable "dev_storage_account_id" {
  type        = string
  description = "Storage account whose blob events feed example-topic"
}

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
  description = "Random suffix for the namespace's global name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}
