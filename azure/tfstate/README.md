# azure/tfstate

Azure port of `aws/tfstate` and `gcp/tfstate`: storage accounts that hold
Terraform state for each environment, plus the Key Vault key, blob events
and access logs around them. Status and change log: `docs/STATUS.md`.
Commands: `../README.az.md`.

Subscription **`bluedragon-sre`** (`8d75b8ef-999c-4f70-99a9-4eb0197f3a07`),
named in every provider block and `backend.hcl`. The az CLI default stays on
grid-meter's subscription; nothing here uses it.

| Env | Region | Bootstrap resource group | State account |
|---|---|---|---|
| dev | `westus2` (Washington) | `bluedragon-tfstate-dev-rg` | `bdtfstatedev` |
| prod | `westus` (California) | `bluedragon-tfstate-prod-rg` | `bdtfstateprod` |

Storage account names are 3-24 lowercase letters and digits and globally
unique, hence `bdtf…` rather than `bluedragon-tfstate-admin-…`.

## AWS / GCP to Azure mapping

| AWS | GCP | Azure |
|---|---|---|
| S3 bucket + versioning | GCS bucket + versioning | Storage account + `tfstate` container, versioning, 7-day soft delete |
| Public access block, ACLs | Uniform access + public access prevention | Public blob access off; **shared keys off**, Entra ID roles only |
| Noncurrent → Glacier 30 d, expire 365 | → Coldline 30 d, delete 365 | Old versions → Cool 30 d, delete 365 (azurerm has no Cold option for versions) |
| Abort multipart 7 d | Abort multipart 7 d | Built in: uncommitted blocks are dropped after 7 days |
| KMS key `alias/tfstate-{env}` | CMEK key ring `tfstate-{env}-{suffix}` | Key Vault `bdtfkv{env}{suffix}`, key `state-key`, via a user-assigned identity |
| Access logs → `-logs` bucket | Usage logs → `-logs` bucket | Diagnostic settings → `bdtflogs…` account (`insights-logs-*` containers) |
| SNS topic (KMS) | Pub/Sub topic (CMEK) | Event Grid system topic (no CMK option) |
| S3 lock file | GCS native lock | Blob lease (native) |
| IAM | IAM | Your login gets **Storage Blob Data Contributor** on each state account; Owner alone can't read blobs |
| (none) | (none) | `bootstrap/dev` adds a $25/month subscription budget alert |

Differences worth knowing:

- **Key Vault names are reserved after delete.** Storage CMK requires purge
  protection, so a destroyed vault stays soft-deleted for 7 days and its name
  can't be reused; the vault name carries the random suffix.
- **Role assignments take a minute to apply.** The keyvault module waits 60 s
  after granting itself and the storage identity access.
- **Event Grid topic has no subscriber**, like the SNS and Pub/Sub topics.

## Prerequisites

```sh
az login                                  # MFA required; keep the default subscription as is
../scripts/register_providers.sh          # once per subscription
```

Copy `terraform.tfvars.example` to `terraform.tfvars` in each root.

## Build

```sh
# 1. bootstrap (local state), dev then prod
cd bootstrap/dev
terraform init
terraform plan -out=bootstrap-dev
terraform apply bootstrap-dev

# 2. environments (state in the bootstrap account, key tfstate/terraform.tfstate)
cd ../../environments/dev
terraform init -backend-config=backend.hcl -reconfigure
terraform plan -out bucket-dev
terraform apply bucket-dev
```

Repeat with `prod`.

## Destroy

```sh
cd environments/prod && terraform destroy
cd ../dev && terraform destroy
cd ../../bootstrap/prod && terraform destroy
cd ../dev && terraform destroy
```

The state accounts hold blobs, so `terraform destroy` fails on them until
emptied; or delete the resource group, which takes everything in it:
`az group delete -n bluedragon-tfstate-<env>-rg --subscription 8d75b8ef-…`.
Destroyed Key Vaults stay soft-deleted for 7 days (free).
