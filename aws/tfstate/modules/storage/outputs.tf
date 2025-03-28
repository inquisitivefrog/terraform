# File 23: modules/storage/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "state_bucket_arn" {
  value       = aws_s3_bucket.state_bucket.arn
  description = "ARN of the S3 state bucket"
}

output "state_log_bucket_arn" {
  value       = aws_s3_bucket.state_log_bucket.arn
  description = "ARN of the S3 state log bucket"
}
