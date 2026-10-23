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

variable "app_repo_url" {
  description = "Public git repo Argo CD reads charts/ecommerce-app from"
  type        = string
  default     = "https://github.com/inquisitivefrog/terraform.git"
}

variable "app_target_revision" {
  description = "Branch, tag or commit Argo CD deploys; pushes to it roll out automatically"
  type        = string
  default     = "main"
}
