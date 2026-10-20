# gcp/tfstate

GCP port of `aws/tfstate`: buckets that hold Terraform state for each
environment, plus the KMS keys, notifications and access logs around them.
Status and change log: `docs/STATUS.md`.

| Env | Region | Bootstrap bucket |
|---|---|---|
| dev | `us-west1` (Oregon) | `bluedragon-tfstate-admin-dev` |
| prod | `us-west2` (Los Angeles) | `bluedragon-tfstate-admin-prod` |

## AWS to GCP mapping

| AWS (`aws/tfstate`) | GCP (`gcp/tfstate`) |
|---|---|
| S3 bucket + versioning | GCS bucket + versioning |
| Public access block, ownership controls, private ACL | Uniform bucket-level access + public access prevention `enforced` |
| Noncurrent → Glacier at 30 days, expire at 365 | Noncurrent → Coldline at 30 days, delete at 365 |
| Abort multipart uploads after 7 days | Same (`AbortIncompleteMultipartUpload`) |
| SSE-KMS with `alias/tfstate-{env}` | CMEK, key ring `tfstate-{env}-{suffix}`, key `state-bucket-key` |
| S3 server access logs → `-logs` bucket, `state-logs/` | GCS usage logs → `-logs` bucket, `state-logs/` |
| SNS topic (KMS-encrypted) + S3 event notifications | Pub/Sub topic `logging-topic-{env}` (CMEK) + GCS notifications |
| S3 lock file (`use_lockfile`) | GCS backend locks natively |
| Account + region per env | One project, region per env |

Differences worth knowing:

- **KMS keys can't be deleted in GCP.** `terraform destroy` destroys the key
  versions and forgets the key ring, but the names stay taken forever. The key
  ring therefore carries the random suffix; a fixed name would block the next
  rebuild. Read the key ID from `terraform output state_bucket_key_id`.
- **Notifications filter by prefix only.** AWS filtered `.tfstate`; GCP
  notifies on every object in the state bucket, lock files included.
- **APIs:** bootstrap enables Cloud KMS, Pub/Sub and Cloud Storage and leaves
  them enabled on destroy.

## Prerequisites (once per laptop)

```sh
gcloud auth login
gcloud auth application-default login   # Terraform uses these credentials
```

Leave the gcloud default project alone: it hosts dairyfarm. This repo's
project (`bluedragon-sre-vuft1e`) comes from `terraform.tfvars`; pass
`--project` to gcloud commands.

Copy `terraform.tfvars.example` to `terraform.tfvars` in each root.

## Build

```sh
# 1. bootstrap (local state), dev then prod
cd bootstrap/dev
terraform init
terraform validate
terraform plan -out=bootstrap-dev
terraform apply bootstrap-dev
gcloud storage ls --project bluedragon-sre-vuft1e

# 2. environments (state in the bootstrap bucket under prefix tfstate/)
cd ../../environments/dev
terraform init -backend-config=backend.hcl -reconfigure
terraform validate
terraform plan -out bucket-dev
terraform apply bucket-dev
terraform state list
terraform output state_bucket_key_id
```

Repeat with `prod` in place of `dev`.

## Destroy

Both buckets in each pair have `force_destroy = false`, so empty them first.

```sh
cd environments/prod && terraform destroy
gcloud storage rm -r --all-versions gs://bluedragon-tfstate-admin-prod-logs-<suffix>/** gs://bluedragon-tfstate-admin-prod-<suffix>/**
# (destroy again if the first run stopped on non-empty buckets)
cd ../dev && terraform destroy   # same emptying step

cd ../../bootstrap/prod && terraform destroy
cd ../dev && terraform destroy
```

The bootstrap buckets hold the environments' state, so empty them
(`gcloud storage rm -r --all-versions gs://<bucket>/**`) only after the
environments are destroyed.
