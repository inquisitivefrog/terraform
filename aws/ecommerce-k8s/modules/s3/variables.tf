# modules/s3/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster (used for tagging)"
  type        = string
}
