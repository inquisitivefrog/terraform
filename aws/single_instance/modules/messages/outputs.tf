# File 8: modules/vpc/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "sns_topic_arns" {
  value = [aws_sns_topic.custom.arn, aws_sns_topic.example.arn]
}

output "sns_topic_example_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.example.arn
}

output "sns_topic_example_policy_arn" {
  value       = aws_sns_topic_policy.example_policy.arn
  description = "ARN of the example SNS topic policy"
}

output "sns_topic_custom_arn" {
  description = "The ARN of the SNS topic"
  value       = aws_sns_topic.custom.arn
}
