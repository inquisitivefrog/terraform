# modules/cluster-config/variables.tf
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "admin_user_arn" {
  type        = string
  description = "ARN of the IAM user for EKS admin access"
}

variable "admin_user_name" {
  type        = string
  description = "Kubernetes username for the admin user"
}

variable "terraform_role_arn" {
  type        = string
  description = "ARN of the IAM role for Terraform admin access"
}

variable "eks_cluster" {
  type        = any
  description = "Reference to the EKS cluster resource"
}
