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
| [aws_elasticache_cluster.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_subnet_group.private_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis Port | `number` | `6379` | no |
| <a name="input_sg_elasticache_id"></a> [sg\_elasticache\_id](#input\_sg\_elasticache\_id) | aws\_security\_group ID | `string` | `""` | no |
| <a name="input_vpc_subnet_private_id"></a> [vpc\_subnet\_private\_id](#input\_vpc\_subnet\_private\_id) | AWS vpc\_subnet ID | `string` | `""` | no |
| <a name="input_vpc_subnet_public_id"></a> [vpc\_subnet\_public\_id](#input\_vpc\_subnet\_public\_id) | AWS vpc\_subnet ID | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_elasticache_arn"></a> [elasticache\_arn](#output\_elasticache\_arn) | n/a |
