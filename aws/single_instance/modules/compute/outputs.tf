# File 15: modules/compute/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ec2_private_id" {
  value = aws_instance.private-ec2.id
}

output "ec2_public_id" {
  value = aws_instance.public-ec2.id
}

output "public_ec2_arn" {
  value       = aws_instance.public-ec2.arn
  description = "ARN of the public EC2 instance"
}

output "private_ec2_arn" {
  value       = aws_instance.private-ec2.arn
  description = "ARN of the private EC2 instance"
}
