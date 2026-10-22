# File 34: modules/eks/variables.tf
# https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-variables

variable "eks_cluster_policy_attachments" {
  type        = list(string)
  description = "List of policy attachment ARNs for EKS cluster role"
}

variable "eks_cluster_role_arn" {
  type        = string
  description = "IAM role ARN for EKS cluster from identity module"
}

variable "eks_cluster_sg_id" {
  type        = string
  description = "Security group ID for EKS cluster from networking module"
}

variable "eks_node_policy_attachments" {
  type        = list(string)
  description = "List of policy attachment ARNs for EKS node role"
}

variable "eks_node_role_arn" {
  type        = string
  description = "IAM role ARN for EKS node group from identity module"
}

variable "eks_version" {
  type        = string
  default     = "1.36"
  description = "Kubernetes version for EKS"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for node group"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encryption"
}

variable "node_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for EKS node group instances"
  default     = []
}

variable "node_desired_size" {
  type        = number
  default     = 3
  description = "Number of worker nodes in the managed node group"
}

variable "node_max_size" {
  type        = number
  default     = 4
  description = "Maximum number of worker nodes in the managed node group"
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "IPv4 CIDRs allowed to reach the public EKS API endpoint"
  validation {
    condition     = length(var.public_access_cidrs) > 0 && !contains(var.public_access_cidrs, "0.0.0.0/0")
    error_message = "Set at least one CIDR (e.g. your laptop's /32); 0.0.0.0/0 is not allowed."
  }
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for resource names"
}

variable "vpc_subnet_private_ids" {
  type        = list(string)
  description = "Private subnet IDs for EKS"
}

