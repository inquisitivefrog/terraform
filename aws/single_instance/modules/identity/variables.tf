# File 24: modules/identity/variables.tf

variable "ec2_arns" {
  type        = list(string)
  description = "List of EC2 instance ARNs"
}

variable "elasticache_arn" {
  type        = string
  description = "ARN of the ElastiCache instance"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS Cluster instance"
}

variable "ecs_service_arn" {
  type        = string
  description = "ARN of the ECS instance"
}

variable "private_ec2_arn" {
  type        = string
  description = "ARN of the private EC2 instance"
}

variable "public_ec2_arn" {
  type        = string
  description = "ARN of the public EC2 instance"
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the developer S3 bucket"
}

variable "sns_topic_arns" { 
  type        = list(string) 
  description = "ARNs of the SNS Topics"
}
