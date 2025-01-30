# File 8: modules/vpc/outputs.tf
# https://developer.hashicorp.com/terraform/language/values/outputs

output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "nat_id" {
  value = aws_nat_gateway.nat.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_subnet_private_id" {
  value = aws_subnet.private.id
}

output "vpc_subnet_private_cidr_block" {
  value = aws_subnet.private.cidr_block
}

output "vpc_subnet_public_id" {
  value = aws_subnet.public.id
}

output "vpc_subnet_public_cidr_block" {
  value = aws_subnet.public.cidr_block
}
