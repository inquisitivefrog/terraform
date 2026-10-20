# gcp/single_instance

GCP port of `aws/single_instance`. State lives in the tfstate layer's
bootstrap bucket under prefix `single_instance`, encrypted with that
environment's `state-bucket-key` (see `backend.hcl`). Build `gcp/tfstate`
first. Status and change log: `../tfstate/docs/STATUS.md`.

| Env | Region / zone | VPC | Pods | Services |
|---|---|---|---|---|
| dev | `us-west1` / `us-west1-a` | `10.1.0.0/16` | `10.101.0.0/16` | `10.201.0.0/20` |
| prod | `us-west2` / `us-west2-a` | `10.0.0.0/16` | `10.100.0.0/16` | `10.200.0.0/20` |

## AWS to GCP mapping

| AWS module | GCP module | Notes |
|---|---|---|
| vpc: VPC, IGW, NAT gateway, 1 public + 2 private subnets, flow logs | vpc: custom VPC, Cloud Router + Cloud NAT, public + private subnet | Subnets are regional, so one private subnet covers both zones. Flow logs go to Cloud Logging. |
| networking: route tables, security groups | networking: firewall rules on network tags | GCP routes are network-wide; "private" means no external IP + NAT. Egress allow-lists end in a priority-65000 deny, as the SGs did. |
| compute: 2 EC2 (Ubuntu 24.04), ECS Fargate nginx | compute: 2 GCE VMs (Ubuntu 24.04), Cloud Run nginx | SSH via OS Login (no key pair). Cloud Run is internal-only with egress through the private subnet; scales to zero. |
| cache: ElastiCache Redis 6.x | cache: Memorystore Redis 7.2 Basic 1 GB | AUTH + TLS on (fixes the AWS open item); daily RDB snapshots. |
| eks: EKS 1.36, managed node group, secrets KMS | gke: zonal GKE Standard, REGULAR channel, private nodes, CMEK secrets | API restricted to laptop + public subnet. Workload Identity on (AWS lacked IRSA). |
| identity: IAM users/group/roles, shared, dev-before-prod | identity: service accounts per env | No shared IAM, so no build order between dev and prod. sre/dba are service accounts that can impersonate admin. |
| kms: EKS, flow-logs, SNS, example symmetric + RSA-3072 keys | kms: key ring per env with GKE, messages, symmetric, RSA-3072 sign keys | No flow-logs key (Logging CMEK is project-wide). Key rings are permanent, so names carry the suffix. |
| messages: SNS example + FIFO topics | messages: Pub/Sub topics | FIFO + dedup = subscription with ordering + exactly-once. |
| storage: dev + log buckets | storage: dev + log buckets | Same lifecycle, logging, notifications; no self-logging loop. |
| kubernetes: namespaces, quotas, RBAC, apps, ALB ingress, aws-auth | kubernetes: same, GKE ingress, cluster-admin binding for the VM identity | Dev only, as in AWS. |

## Build

```sh
cd environments/dev                  # then prod
curl -4 ifconfig.me                  # must match my_laptop_cidr_block
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out plan-dev
terraform apply plan-dev
$(terraform output -raw kubeconfig_command)
```

## Reach the VMs

```sh
../scripts/ssh_vm.sh dev               # public VM, through IAP
../scripts/ssh_vm.sh dev private       # private VM, through the public one
../scripts/kube_use.sh dev             # kubectl via ~/.kube/gcp-dev
../scripts/check_resources.sh dev      # verify everything is up
../scripts/estimate_costs.sh all       # list-price estimate of what's running
```

Details and the raw gcloud commands: `../README.gcloud.md`.

## Destroy

```sh
cd environments/prod && terraform destroy
cd ../dev
terraform destroy -target=module.kubernetes   # then wait for the ingress LB to go
terraform destroy                    # dev_bucket has force_destroy = false; empty it first
```

Expect to run the last `terraform destroy` again 1-2 hours later: Cloud Run's
serverless IP holds the private subnet. See "Teardown" in `../README.gcloud.md`.
