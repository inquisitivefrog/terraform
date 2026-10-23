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

variable "my_laptop_cidr_block" {
  type        = string
  description = "Only source allowed through the Argo CD load balancer and the app ALB, e.g. \"<laptop IP>/32\" (curl -4 ifconfig.me)"
}
