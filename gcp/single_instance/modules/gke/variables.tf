# modules/gke/variables.tf

variable "authorized_cidrs" {
  type = list(object({
    cidr = string
    name = string
  }))
  description = "CIDRs allowed to reach the GKE API endpoint"
  validation {
    condition     = length(var.authorized_cidrs) > 0 && !contains([for c in var.authorized_cidrs : c.cidr], "0.0.0.0/0")
    error_message = "Set at least one CIDR (e.g. your laptop's /32); 0.0.0.0/0 is not allowed."
  }
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "kms_key_id" {
  type        = string
  description = "KMS key for secrets encryption"
}

variable "machine_type" {
  type        = string
  description = "Node machine type"
}

variable "network_id" {
  type        = string
  description = "VPC network ID"
}

variable "node_count" {
  type        = number
  description = "Initial node count"
}

variable "node_max_count" {
  type        = number
  description = "Maximum node count"
}

variable "node_sa_email" {
  type        = string
  description = "Node service account"
}

variable "node_tag" {
  type        = string
  description = "Network tag on nodes"
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for resource names"
}

variable "subnet_private_id" {
  type        = string
  description = "Private subnet with pods and services secondary ranges"
}

variable "zone" {
  type        = string
  description = "Cluster zone"
}
