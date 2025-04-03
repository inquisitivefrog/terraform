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
| [aws_kms_alias.sns_custom_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.asymmetric_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.sns_custom_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.symmetric_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.vpc_flow_logs_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for Flow Logs | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asymmetric_key_arn"></a> [asymmetric\_key\_arn](#output\_asymmetric\_key\_arn) | ARN of the asymmetric KMS key |
| <a name="output_sns_custom_key_alias_arn"></a> [sns\_custom\_key\_alias\_arn](#output\_sns\_custom\_key\_alias\_arn) | ARN of the custom KMS key alias for SNS |
| <a name="output_sns_custom_key_arn"></a> [sns\_custom\_key\_arn](#output\_sns\_custom\_key\_arn) | ARN of the custom KMS key for SNS |
| <a name="output_symmetric_key_arn"></a> [symmetric\_key\_arn](#output\_symmetric\_key\_arn) | ARN of the symmetric KMS key |
| <a name="output_vpc_flow_logs_key_arn"></a> [vpc\_flow\_logs\_key\_arn](#output\_vpc\_flow\_logs\_key\_arn) | ARN of the KMS key for VPC Flow Logs |
| <a name="output_vpc_flow_logs_key_id"></a> [vpc\_flow\_logs\_key\_id](#output\_vpc\_flow\_logs\_key\_id) | ID of the KMS key for VPC Flow Logs |
| <a name="output_vpc_flow_logs_key_resource"></a> [vpc\_flow\_logs\_key\_resource](#output\_vpc\_flow\_logs\_key\_resource) | n/a |
