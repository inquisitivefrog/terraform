# modules/aks/variables.tf

variable "authorized_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the AKS API"
  validation {
    condition     = length(var.authorized_cidrs) > 0 && !contains(var.authorized_cidrs, "0.0.0.0/0")
    error_message = "Set at least one CIDR (e.g. your laptop's /32); 0.0.0.0/0 is not allowed."
  }
}

variable "cluster_identity_id" {
  type        = string
  description = "User-assigned identity for the control plane"
}

variable "cluster_identity_principal_id" {
  type        = string
  description = "Principal ID of that identity"
}

variable "enable_ingress" {
  type        = bool
  default     = false
  description = "Enable the managed NGINX ingress (app routing add-on)"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault holding the KMS key"
}

variable "kms_key_id" {
  type        = string
  description = "Versioned Key Vault key ID for etcd encryption"
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Kubernetes version; null takes AKS's default"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "node_count" {
  type        = number
  description = "Initial node count"
}

variable "node_max_count" {
  type        = number
  description = "Maximum node count"
}

variable "node_vm_size" {
  type        = string
  description = "Node VM size"
}

variable "pods_cidr_block" {
  type        = string
  description = "Overlay pod range"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group"
}

variable "services_cidr_block" {
  type        = string
  description = "Service range (DNS service IP is its .10)"
}

variable "subnet_id" {
  type        = string
  description = "Node subnet (private, with NAT gateway)"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
}
