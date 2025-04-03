## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.private_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.public_ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_igw_id"></a> [igw\_id](#input\_igw\_id) | resource ID | `string` | `""` | no |
| <a name="input_my_laptop_cidr_block"></a> [my\_laptop\_cidr\_block](#input\_my\_laptop\_cidr\_block) | SSH access outside NAT | `string` | `""` | no |
| <a name="input_nat_id"></a> [nat\_id](#input\_nat\_id) | resource ID | `string` | `""` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis Port | `number` | `6379` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | IPv4 address range | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | resource ID | `string` | `""` | no |
| <a name="input_vpc_subnet_private_cidr_block"></a> [vpc\_subnet\_private\_cidr\_block](#input\_vpc\_subnet\_private\_cidr\_block) | IPv4 subnet ID | `string` | `""` | no |
| <a name="input_vpc_subnet_private_id"></a> [vpc\_subnet\_private\_id](#input\_vpc\_subnet\_private\_id) | AWS vpc\_subnet ID | `string` | `""` | no |
| <a name="input_vpc_subnet_public_cidr_block"></a> [vpc\_subnet\_public\_cidr\_block](#input\_vpc\_subnet\_public\_cidr\_block) | IPv4 subnet ID | `string` | `""` | no |
| <a name="input_vpc_subnet_public_id"></a> [vpc\_subnet\_public\_id](#input\_vpc\_subnet\_public\_id) | AWS vpc\_subnet ID | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sg_elasticache_id"></a> [sg\_elasticache\_id](#output\_sg\_elasticache\_id) | n/a |
| <a name="output_sg_private_ec2_id"></a> [sg\_private\_ec2\_id](#output\_sg\_private\_ec2\_id) | n/a |
| <a name="output_sg_public_ec2_id"></a> [sg\_public\_ec2\_id](#output\_sg\_public\_ec2\_id) | n/a |
