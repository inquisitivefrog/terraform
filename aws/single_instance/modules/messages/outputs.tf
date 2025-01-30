# File 8: modules/vpc/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "sns_topic_example_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.example.arn
}

output "sns_topic_custom_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.custom.arn
}

