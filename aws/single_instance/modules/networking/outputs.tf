# File 12: modules/networking/outputs.tf 
# https://developer.hashicorp.com/terraform/language/values/outputs

output "sg_public_ec2_id" {
  value = aws_security_group.public_ec2.id
}

output "sg_private_ec2_id" {
  value = aws_security_group.private_ec2.id
}

output "sg_elasticache_id" {
  value = aws_security_group.elasticache.id
}
