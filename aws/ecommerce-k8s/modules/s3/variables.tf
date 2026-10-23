# modules/s3/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster (used for tagging)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key for the bucket's default encryption"
  type        = string
}
