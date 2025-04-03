## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.93.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cache"></a> [cache](#module\_cache) | ../../modules/cache | n/a |
| <a name="module_compute"></a> [compute](#module\_compute) | ../../modules/compute | n/a |
| <a name="module_identity"></a> [identity](#module\_identity) | ../../modules/identity | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../modules/kms | n/a |
| <a name="module_messages"></a> [messages](#module\_messages) | ../../modules/messages | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ../../modules/networking | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ../../modules/storage | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | AWS Availability Zone within Region where resources deployed | `list(string)` | `[]` | no |
| <a name="input_ec2_keypair"></a> [ec2\_keypair](#input\_ec2\_keypair) | AWS EC2 keypair name | `string` | `"nobody"` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment where resources are deployed | `string` | `"develop"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | AWS EC2 instance\_type | `string` | `""` | no |
| <a name="input_my_laptop_cidr_block"></a> [my\_laptop\_cidr\_block](#input\_my\_laptop\_cidr\_block) | SSH client access IPv4 range | `string` | `""` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | Redis network cache port | `number` | `6379` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where resources deployed | `string` | `"us-west-1"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | IPv4 network address range | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_sns_topic_example_arn"></a> [sns\_topic\_example\_arn](#output\_sns\_topic\_example\_arn) | The ARN of the example SNS topic |
