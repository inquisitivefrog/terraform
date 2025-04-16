# File 15: modules/compute/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.main.arn
}
output "ecs_service_arn" {
  value = aws_ecs_service.main.id
}

output "ec2_arns" {
  value = [aws_instance.public-ec2.arn, aws_instance.private-ec2.arn]
}

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

output "public_ec2_sg_id" {
  value       = tolist(aws_instance.public-ec2.vpc_security_group_ids)[0]
  description = "Security group ID for public EC2 instance"
}
