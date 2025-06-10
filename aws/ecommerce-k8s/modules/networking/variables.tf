# modules/networking/variables.tf
variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security group ID for the EKS cluster"
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS cluster endpoint publicly"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of private route table IDs for VPC endpoints"
  type        = list(string)
}

variable "app_port" {
  description = "Port for the application security group"
  type        = number
  default     = 8080
}
