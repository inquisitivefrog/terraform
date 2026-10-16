# File 9: modules/kms/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "sns_logging_key_arn" {
  value       = aws_kms_key.sns_logging_key.arn
  description = "ARN of the KMS key for S3 state log bucket logging"
}

output "state_bucket_key_arn" {
  value       = aws_kms_key.state_bucket_key.arn
  description = "ARN of the KMS key for S3 state bucket"
}

output "state_bucket_key_alias_arn" {
  value       = aws_kms_alias.state_bucket_key.arn
  description = "ARN of the state bucket KMS key alias, for kms_key_id in backend.hcl"
}
