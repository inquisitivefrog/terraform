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
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc_flow_logs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_iam_role.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | AWS Availability Zones within Region where resources deployed | `list(string)` | `[]` | no |
| <a name="input_create_iam_resources"></a> [create\_iam\_resources](#input\_create\_iam\_resources) | Whether to create IAM resources or reference existing ones | `bool` | `true` | no |
| <a name="input_kms_key_resource"></a> [kms\_key\_resource](#input\_kms\_key\_resource) | The KMS key resource for VPC Flow Logs encryption | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where resources deployed | `string` | `"us-west-1"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | IPv4 address range | `string` | `""` | no |
| <a name="input_vpc_flow_logs_key_arn"></a> [vpc\_flow\_logs\_key\_arn](#input\_vpc\_flow\_logs\_key\_arn) | ARN of the KMS key for VPC Flow Logs encryption | `string` | n/a | yes |
| <a name="input_vpc_flow_logs_key_id"></a> [vpc\_flow\_logs\_key\_id](#input\_vpc\_flow\_logs\_key\_id) | ID of the KMS key for VPC Flow Logs encryption | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | n/a |
| <a name="output_nat_id"></a> [nat\_id](#output\_nat\_id) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
| <a name="output_vpc_subnet_private_cidr_block"></a> [vpc\_subnet\_private\_cidr\_block](#output\_vpc\_subnet\_private\_cidr\_block) | n/a |
| <a name="output_vpc_subnet_private_id"></a> [vpc\_subnet\_private\_id](#output\_vpc\_subnet\_private\_id) | n/a |
| <a name="output_vpc_subnet_public_cidr_block"></a> [vpc\_subnet\_public\_cidr\_block](#output\_vpc\_subnet\_public\_cidr\_block) | n/a |
| <a name="output_vpc_subnet_public_id"></a> [vpc\_subnet\_public\_id](#output\_vpc\_subnet\_public\_id) | n/a |
