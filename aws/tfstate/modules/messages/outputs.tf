# File 8: modules/vpc/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "sns_topic_logging_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.logging.arn
}

output "sns_topic_logging_policy_arn" {
  description = "The ARN of the SNS topic logging policy"
  value       = aws_sns_topic_policy.allow_s3.arn
}
