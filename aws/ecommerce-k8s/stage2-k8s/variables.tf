# stage2-k8s/variables.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "ecommerce-cluster"
}

variable "admin_user_name" {
  description = "IAM user name for admin access"
  type        = string
}

variable "terraform_role_arn" {
  description = "ARN of the terraform-admin IAM role"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the node group IAM role"
  type        = string
}

variable "alb_controller_role_arn" {
  description = "ARN of the ALB controller IAM role"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
