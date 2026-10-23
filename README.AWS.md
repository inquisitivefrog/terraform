# https://github.com/inquisitivefrog/terraform

This repository demonstrates use of Terraform to create environments in
Amazon Web Services (and, since October 2026, ports of the same design to
GCP in `gcp/` and Azure in `azure/`). Everything it creates is demo data:
the value is reproducible code and notes, so tear down and rebuild freely.

All work was completed with the assistance of xAI Grok Generative Text tool.

## Account and region

Since 2026-10-22: account `650836812595` (Free plan, credits until
2027-04-22), CLI profile `blue-elephant`, region `us-east-2` for dev, prod
and ecommerce-k8s. An SCP from the organization's management account denies
every other region. Providers and backends pin the profile, and providers set
`allowed_account_ids`; the scripts read the same settings from
`aws/scripts/aws_env.sh`. (Until 2026-10-21 everything ran in account
`084375569056`, us-west-2 and us-west-1, with `bluedragon` names.)

## Layout (`aws/`)

| Root | Creates | State |
|---|---|---|
| `tfstate/bootstrap/{dev,prod}` | State bucket `blue-elephant-tfstate-admin-{env}` and its log bucket | local `terraform.tfstate` |
| `tfstate/environments/{dev,prod}` | KMS key `alias/tfstate-{env}` that encrypts single_instance state | bootstrap bucket, key `terraform.tfstate` |
| `single_instance/environments/{dev,prod}` | VPC, EC2 (public + private), EKS, ECS, ElastiCache Redis, SNS, S3, IAM; names end in `-{env}` | bootstrap bucket, key `single_instance/terraform.tfstate` |
| `ecommerce-k8s/` | Separate EKS project (two stages) | its own bucket `blue-elephant-ecommerce-terraform-state` |

Shared IAM (users, roles, DeveloperPolicy, AdminPolicy) is global, so dev
creates it and prod reads it: apply dev before prod, destroy prod before dev.
EC2 key pair: `blue-elephant` (private key `~/.ssh/aws_ssh`), one for both
environments.

## Build and tear down

Step-by-step table, including the state-object step that tear-down needs:
`aws/README.aws.md`, "Build and tear-down order". In short: bootstrap, then
environments, then single_instance (dev before prod); verify with
`aws/scripts/check_resources.sh <env>`. `aws/scripts/aws_wipe.sh` removes the
tfstate layer once single_instance is destroyed.

Check `curl -4 ifconfig.me` against `my_laptop_cidr_block` in each
`terraform.tfvars` first: the EKS API and SSH allow only that address.

## More

- Status, change log, open items: `aws/tfstate/docs/STATUS.md`
- aws CLI commands and build order: `aws/README.aws.md`
- Test and scan tools (tflint, trivy, checkov): `aws/README.aws.test.md`
- Repo checks (hook, GitHub Action): `docs/REPO_CHECKS.md`
- Cost: `aws/scripts/estimate_costs.sh`; kubectl and SSH: `aws/scripts/kube_use.sh`, `aws/scripts/ssh_ec2.sh`
