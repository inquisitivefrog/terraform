# modules/storage/variables.tf

variable "cmk" {
  type = object({
    key_id      = string # versionless Key Vault key ID
    identity_id = string # user-assigned identity with access to the key
  })
  default     = null
  description = "Customer-managed key; null uses Microsoft-managed keys (bootstrap)"
}

variable "data_principal_id" {
  type        = string
  description = "Object ID granted Storage Blob Data Contributor on the state account (you)"
}

variable "employer" {
  type        = string
  description = "Employer that owns environment deployed"
}

variable "env" {
  type        = string
  description = "Environment where resources are deployed"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for name uniqueness; empty for bootstrap"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the storage accounts"
}
