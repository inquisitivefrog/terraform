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
| [aws_sns_topic.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.example_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS Account ID for tagging purposes | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment this VPC is being deployed to | `string` | n/a | yes |
| <a name="input_log_bucket_arn"></a> [log\_bucket\_arn](#input\_log\_bucket\_arn) | ARN of the log bucket for SNS notifications | `string` | n/a | yes |
| <a name="input_s3_bucket_arn"></a> [s3\_bucket\_arn](#input\_s3\_bucket\_arn) | ARN of the developer S3 bucket | `string` | n/a | yes |
| <a name="input_sns_custom_key_arn"></a> [sns\_custom\_key\_arn](#input\_sns\_custom\_key\_arn) | ARN of the custom KMS key for SNS encryption | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_arns"></a> [sns\_topic\_arns](#output\_sns\_topic\_arns) | n/a |
| <a name="output_sns_topic_custom_arn"></a> [sns\_topic\_custom\_arn](#output\_sns\_topic\_custom\_arn) | The ARN of the SNS topic |
| <a name="output_sns_topic_example_arn"></a> [sns\_topic\_example\_arn](#output\_sns\_topic\_example\_arn) | The ARN of the SNS topic |
| <a name="output_sns_topic_example_policy_arn"></a> [sns\_topic\_example\_policy\_arn](#output\_sns\_topic\_example\_policy\_arn) | ARN of the example SNS topic policy |
