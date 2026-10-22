# File 24: modules/identity/variables.tf

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "create_iam_resources" {
  type        = bool
  default     = true
  description = "Whether to create IAM resources or reference existing ones"
}

variable "enable_ingress" {
  type        = bool
  default     = false
  description = "Enable ALB controller IAM role creation"
}

variable "env" {
  type        = string
  description = "Environment name (e.g., prod, dev)"
}

variable "private_ec2_arn" {
  type        = string
  description = "ARN of the private EC2 instance"
}

variable "public_ec2_arn" {
  type        = string
  description = "ARN of the public EC2 instance"
}

variable "random_suffix" {
  type        = string
  description = "Random suffix for resource names"
}

variable "project_tag" {
  type        = string
  default     = "blue-elephant-single-instance"
  description = "Value of the Project tag on EC2 instances; AdminPolicy's ec2:* is limited to it"
}
