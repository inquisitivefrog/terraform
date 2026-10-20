# azure/single_instance

Azure port of `aws/single_instance` and `gcp/single_instance`, in subscription
**`bluedragon-sre`** (`8d75b8ef-…`). State lives in the tfstate layer's
Key Vault-encrypted environments account (`bdtfstate<env><suffix>`, key
`single_instance/terraform.tfstate`; see `backend.hcl`). Build `azure/tfstate`
and run `../scripts/register_providers.sh` first. Status: `../tfstate/docs/STATUS.md`.
Commands: `../README.az.md`.

| Env | Region | VNet | Pods (overlay) | Services |
|---|---|---|---|---|
| dev | `westus2` | `10.1.0.0/16` | `10.101.0.0/16` | `10.201.0.0/20` |
| prod | `westus` | `10.0.0.0/16` | `10.100.0.0/16` | `10.200.0.0/20` |

Sizes: the subscription can't use B-series in these regions
(`../scripts/vm_sizes.sh`), so VMs are `Standard_F1als_v7` (1 vCPU, 2 GB) and
AKS nodes `Standard_D2als_v7` (2 vCPU, 4 GB). 2 nodes (max 3) + 2 VMs fit the
10-vCPU regional quota.

## AWS / GCP to Azure mapping

| AWS | GCP | Azure | Notes |
|---|---|---|---|
| VPC, IGW, NAT gateway, subnets, flow logs | VPC, Cloud NAT, subnets, flow logs | VNet, NAT gateway, subnets public/private/endpoints/apps, VNet flow logs to the logs account | Network Watcher created here before the VNet so Azure doesn't add its own |
| Security groups | Firewall rules on tags | NSGs on each VM's NIC | Not on the subnet: AKS nodes share it. Ends in deny-all at 4000 |
| 2 EC2 (Ubuntu 24.04) | 2 GCE VMs | 2 Linux VMs, Trusted Launch, user-assigned identity | SSH key `~/.ssh/bluedragon_azure` (personal accounts can't use Entra SSH login); public VM's sshd also on 2222 |
| ECS Fargate nginx | Cloud Run (internal) | Container Apps, internal environment, scale to zero | Private DNS zone for the environment's domain |
| ElastiCache Redis 6 | Memorystore Redis 7.2 | Azure Managed Redis `Balanced_B0` | TLS on 10000, access key, private endpoint, public access off |
| EKS 1.36 | GKE | AKS Free tier, CNI overlay + Cilium, NAT egress, KMS (Key Vault) secrets, Workload Identity | API limited to laptop, NAT IP, public VM IP |
| IAM users/roles | Service accounts | User-assigned identities + role assignments | Namespace roles via Azure RBAC for Kubernetes (custom role: pods/services get/list/create/delete) |
| KMS keys | KMS key ring | Key Vault (purge protection, suffix) with aks-kms, messages, symmetric (RSA), asymmetric (RSA-3072 sign) keys | Standard vaults have no AES keys |
| SNS example + FIFO topics | Pub/Sub topics | Service Bus Standard: example-topic (blob events via Event Grid) and custom-topic (ordering + duplicate detection, session subscription) | No https subscription to example.com: Event Grid webhooks need a validation handshake |
| S3 dev + log buckets | GCS dev + log buckets | Storage accounts with CMK, `logs` container expiring at 90 days, access logs to the logs account | Shared keys off |
| Kubernetes layer, ALB ingress | Kubernetes layer, GKE ingress | Same, ingress on AKS's managed NGINX (app routing) | Dev only |

## Build

```sh
cd environments/dev                  # then prod
curl -4 ifconfig.me                  # must match my_laptop_cidr_block
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out plan-dev
terraform apply plan-dev
../../../scripts/check_resources.sh dev   # once single_instance checks are added
```

## Destroy

```sh
cd environments/dev && terraform destroy
```

Key Vaults stay soft-deleted for 7 days after destroy (names reserved, free).
