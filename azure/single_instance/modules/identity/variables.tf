# modules/identity/variables.tf

variable "aks_cluster_id" {
  type        = string
  description = "AKS cluster the VM identity administers"
}

variable "asymmetric_key_resource_id" {
  type        = string
  description = "Signing key the developer may use"
}

variable "container_app_id" {
  type        = string
  description = "Container app the admin manages"
}

variable "dev_storage_account_id" {
  type        = string
  description = "Developer storage account"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault the admin manages"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "namespace_roles" {
  type        = map(string)
  default     = {}
  description = "Identity (sre, dba) => Kubernetes namespace it may manage pods and services in"
}

variable "redis_id" {
  type        = string
  description = "Managed Redis the admin manages"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "servicebus_namespace_id" {
  type        = string
  description = "Service Bus namespace the admin manages"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}

variable "vm_ids" {
  type        = list(string)
  description = "VM IDs for resource-level grants"
}
