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
| [aws_ecs_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_instance.private-ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.public-ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ec2_instance_profile_name"></a> [ec2\_instance\_profile\_name](#input\_ec2\_instance\_profile\_name) | Name of the IAM instance profile for EC2 instances | `string` | n/a | yes |
| <a name="input_ec2_keypair"></a> [ec2\_keypair](#input\_ec2\_keypair) | AWS EC2 key pair name | `string` | `""` | no |
| <a name="input_ecs_task_execution_role_arn"></a> [ecs\_task\_execution\_role\_arn](#input\_ecs\_task\_execution\_role\_arn) | AWS IAM Role for ECS with Fargate | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | AWS instance\_type. VM footprint | `string` | `""` | no |
| <a name="input_sg_private_ec2_id"></a> [sg\_private\_ec2\_id](#input\_sg\_private\_ec2\_id) | aws\_security\_group ID | `string` | `""` | no |
| <a name="input_sg_public_ec2_id"></a> [sg\_public\_ec2\_id](#input\_sg\_public\_ec2\_id) | aws\_security\_group ID | `string` | `""` | no |
| <a name="input_vpc_subnet_private_id"></a> [vpc\_subnet\_private\_id](#input\_vpc\_subnet\_private\_id) | IPv4 subnet ID | `string` | `""` | no |
| <a name="input_vpc_subnet_public_id"></a> [vpc\_subnet\_public\_id](#input\_vpc\_subnet\_public\_id) | IPv4 subnet ID | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_arns"></a> [ec2\_arns](#output\_ec2\_arns) | n/a |
| <a name="output_ec2_private_id"></a> [ec2\_private\_id](#output\_ec2\_private\_id) | n/a |
| <a name="output_ec2_public_id"></a> [ec2\_public\_id](#output\_ec2\_public\_id) | n/a |
| <a name="output_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#output\_ecs\_cluster\_arn) | n/a |
| <a name="output_ecs_service_arn"></a> [ecs\_service\_arn](#output\_ecs\_service\_arn) | n/a |
| <a name="output_private_ec2_arn"></a> [private\_ec2\_arn](#output\_private\_ec2\_arn) | ARN of the private EC2 instance |
| <a name="output_public_ec2_arn"></a> [public\_ec2\_arn](#output\_public\_ec2\_arn) | ARN of the public EC2 instance |
