# https://github.com/inquisitivefrog/terraform

This repository demonstrates use of Terraform to create environments in
Amazon Web Services (and, since October 2026, ports of the same design to
GCP in `gcp/` and Azure in `azure/`).

All work was completed with the assistance of xAI Grok Generative Text tool.

## Layout (`aws/`)

| Root | Creates | State |
|---|---|---|
| `tfstate/bootstrap/{dev,prod}` | State bucket `bluedragon-tfstate-admin-{env}` and its log bucket | local `terraform.tfstate` |
| `tfstate/environments/{dev,prod}` | KMS key `alias/tfstate-{env}` that encrypts single_instance state | bootstrap bucket, key `terraform.tfstate` |
| `single_instance/environments/{dev,prod}` | VPC, EC2 (public + private), EKS, ECS, ElastiCache Redis, SNS, S3, IAM | bootstrap bucket, key `single_instance/terraform.tfstate` |
| `ecommerce-k8s/` | Separate project (us-east-1); not plan-tested | its own bucket |

dev runs in us-west-2, prod in us-west-1. Shared IAM (users, roles,
DeveloperPolicy, AdminPolicy) is global, so dev creates it and prod reads it:
apply dev before prod.

## Build (from scratch)

In each directory: `terraform init` (with `-backend-config=backend.hcl
-reconfigure` where a `backend.hcl` exists), `terraform plan -out <file>`,
`terraform apply <file>`.

1. `aws/tfstate/bootstrap/dev`, `aws/tfstate/bootstrap/prod`
2. `aws/tfstate/environments/dev`, `aws/tfstate/environments/prod`
3. EC2 key pair `bluedragon` imported in each region (see the status file)
4. `aws/single_instance/environments/dev`, then `prod`

Check `curl -4 ifconfig.me` against `my_laptop_cidr_block` in each
`terraform.tfvars` first: the EKS API and SSH allow only that address.

## Tear down

`terraform destroy` single_instance prod, then dev; then run
`aws/scripts/aws_wipe.sh` for the tfstate layer (it empties the versioned
buckets and destroys environments, then bootstrap, in order).

## More

- Status, change log, open items: `aws/tfstate/docs/STATUS.md`
- aws CLI commands: `aws/README.aws.md`
- Test and scan tools (tflint, trivy, checkov): `aws/README.aws.test.md`
- Repo checks (hook, GitHub Action): `docs/REPO_CHECKS.md`
- kubectl and SSH: `aws/single_instance/docs/KUBECTL.md`, `aws/scripts/kube_use.sh`, `aws/scripts/ssh_ec2.sh`
