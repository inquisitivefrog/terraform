# File 23: modules/storage/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "s3_bucket_arn" {
  value       = aws_s3_bucket.dev_bucket.arn
  description = "ARN of the dev S3 bucket"
}

output "log_bucket_arn" {
  value       = aws_s3_bucket.log_bucket.arn
  description = "ARN of the log bucket"
}
