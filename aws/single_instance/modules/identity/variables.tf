# File 24: modules/identity/variables.tf

variable "public_ec2_arn" {
  type        = string
  description = "ARN of the public EC2 instance"
}

variable "private_ec2_arn" {
  type        = string
  description = "ARN of the private EC2 instance"
}

# modules/identity/variables.tf
variable "ec2_arns" {
  type        = list(string)
  description = "List of EC2 instance ARNs"
}
variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the developer S3 bucket"
}
