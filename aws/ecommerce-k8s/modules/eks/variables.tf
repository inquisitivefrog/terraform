# modules/eks/variables.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the cluster endpoint publicly"
  type        = list(string)
}

variable "cluster_enabled_log_types" {
  description = "List of enabled log types for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "Configuration for EKS managed node groups"
  type        = map(any)
}
