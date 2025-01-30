# File 15: modules/compute/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "ec2_private_id" {
  value = aws_instance.private-ec2.id
}

output "ec2_public_id" {
  value = aws_instance.public-ec2.id
}

