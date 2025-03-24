# File 9: modules/kms/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "asymmetric_key_arn" {
  value       = aws_kms_key.asymmetric_key.arn
  description = "ARN of the asymmetric KMS key"
}

output "sns_custom_key_alias_arn" {
  value       = aws_kms_alias.sns_custom_key_alias.arn
  description = "ARN of the custom KMS key alias for SNS"
}

output "sns_custom_key_arn" {
  value       = aws_kms_key.sns_custom_key.arn
  description = "ARN of the custom KMS key for SNS"
}

output "symmetric_key_arn" {
  value       = aws_kms_key.symmetric_key.arn
  description = "ARN of the symmetric KMS key"
}

output "vpc_flow_logs_key_arn" {
  value       = aws_kms_key.vpc_flow_logs_key.arn
  description = "ARN of the KMS key for VPC Flow Logs"
}

output "vpc_flow_logs_key_id" {
  value       = aws_kms_key.vpc_flow_logs_key.id
  description = "ID of the KMS key for VPC Flow Logs"
}

output "vpc_flow_logs_key_resource" {
  value       = aws_kms_key.vpc_flow_logs_key
}
