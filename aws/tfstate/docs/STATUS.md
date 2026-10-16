# Status: AWS Terraform rebuild

Rolling record of how this repo looked when the rebuild started, what has
changed since, and what is deployed. Add new entries at the top of the
change log, and update "Current state" and "Open items" when they change.

- Account: `084375569056`
- IAM user: `bluedragon`
- Regions: dev = `us-west-2`, prod = `us-west-1`
- Terraform: AWS provider `~> 6.65` (6.69.1 installed)

## Current state (2026-10-16)

### Deployed in AWS

| Layer | dev (us-west-2) | prod (us-west-1) |
|---|---|---|
| `tfstate/bootstrap` (local state) | `bluedragon-tfstate-admin-dev` + `-logs`, SSE-S3 | `bluedragon-tfstate-admin-prod` + `-logs`, SSE-S3 |
| `tfstate/environments` (state in bootstrap bucket, key `terraform.tfstate`) | suffix `gmeemt5w`: KMS `state_bucket_key` `39173157-…` + `alias/tfstate-dev`, SNS key, `logging-topic`, suffixed buckets | suffix `l4ilb4si`: KMS `state_bucket_key` `5a0c9bd2-…` + `alias/tfstate-prod`, SNS key, `logging-topic`, suffixed buckets |
| EC2 key pair `bluedragon` | matches `~/.aws/bluedragon_uswest2.pem` | matches `~/.aws/bluedragon_uswest1.pem` (same key as `~/.aws/bluedragon.pem`) |
| `single_instance` | initialized, not applied | initialized, not applied |
| `ecommerce-k8s` | not deployed (uses its own state bucket in us-east-1) | — |

Unrelated bucket in the same account: `grid-meter-app-tfstate-084375569056`
holds another project's Terraform state. Do not delete it.

### Where state lives

| Root | Bucket | Key | Encryption |
|---|---|---|---|
| `tfstate/bootstrap/{env}` | local `terraform.tfstate` | — | — |
| `tfstate/environments/{env}` | `bluedragon-tfstate-admin-{env}` | `terraform.tfstate` | SSE-S3 |
| `single_instance/environments/{env}` | `bluedragon-tfstate-admin-{env}` | `single_instance/terraform.tfstate` | SSE-KMS via `alias/tfstate-{env}` |
| `ecommerce-k8s/*` | `bluedragon-ecommerce-terraform-state` (us-east-1) | per stage | — |

Locking uses S3 native lock files (`use_lockfile = true`); no DynamoDB table.

## Build order (from scratch)

1. `tfstate/bootstrap/{dev,prod}`: `terraform init`, `plan -out bootstrap-{env}`, `apply bootstrap-{env}`
2. `tfstate/environments/{dev,prod}`: `terraform init -upgrade -backend-config=backend.hcl -reconfigure`, `plan -out bucket-{env}`, `apply bucket-{env}`
3. Import the EC2 key pair per region:
   `ssh-keygen -y -f ~/.aws/<key>.pem > /tmp/<key>.pub` then
   `aws ec2 import-key-pair --key-name bluedragon --public-key-material fileb:///tmp/<key>.pub --region <region>`
4. `single_instance/environments/{dev,prod}`: `terraform init -upgrade -backend-config=backend.hcl -reconfigure`, then plan/apply
   (blocked until the EKS items under "Open items" are fixed)

Saved plan files (`plan-*`, `bootstrap-*`, `bucket-*`, `dev-bucket`, `prod-bucket`)
are git-ignored. Provider lock files are git-ignored and machine-local; if
`init` reports a checksum mismatch, delete `.terraform.lock.hcl` and re-run init.

## Change log

### 2026-10-16

- **Commit (this file):** Added `alias/tfstate-{env}` on the tfstate stage's
  state KMS key; `single_instance` `backend.hcl` now sets `kms_key_id` to that
  alias, so single_instance state is KMS-encrypted. Applied the alias in dev
  and prod. Removed stale Intel-era lock files in `single_instance/environments`
  and re-initialized. Removed obsolete `tiller` entry from top-level `README.md`.
- **Applied:** logging fixes from `8f4206f` to all four tfstate roots
  (bootstrap 3 changes each; environments 4 changes + 1 destroy each).
- `8f4206f` Fix tfstate access logging and notifications:
  log bucket SSE-S3 (access log targets cannot use SSE-KMS), log bucket policy
  principal `logging.s3.amazonaws.com`, notifications filter on `.tfstate` and
  `state-logs/`, removed unused log-bucket KMS key, bootstrap no longer uses
  placeholder `key/dummy` ARNs.
- **Applied:** `tfstate/environments/{dev,prod}` (21 resources each).
- `ee9d315` Give single_instance its own state key: single_instance and the
  tfstate stage both used `terraform.tfstate` in the same bucket; a
  single_instance plan would have destroyed the tfstate stage's resources.

### 2026-10-15

- **AWS:** All resources for every project under this repo were wiped
  beforehand; IAM user `bluedragon` and the account remain. New access key
  created for `bluedragon` (the old key ending `IAEZ` was invalid).
- **Applied:** `tfstate/bootstrap/{dev,prod}` (13 resources each). Imported
  EC2 key pair `bluedragon` in us-west-1 and us-west-2.
- `2456e28` Parameterize account, admin user and key pair; upgrade AWS
  provider to 6.x: account ID from `aws_caller_identity`; new variables
  `admin_user_name`, `ssh_private_key_path`; `ec2_keypair` required; values in
  `terraform.tfvars`; identity module derives KMS region from the provider;
  all AWS provider pins `~> 6.65`.
- `05f08e1` Single-cluster EKS module; fix dev env, scripts, and repo hygiene:
  EKS module one cluster per env with AMI lookup; dev env rewired to it;
  kubernetes module pins helm 2.x and uses `var.region`; `cleanup_aws_2.sh`
  syntax fix and confirmation before deleting tfstate buckets; `scan_aws.sh`
  ordering fix; stopped tracking binary plan files; redacted access key IDs;
  `terraform fmt -recursive`.
- Retired the pre-commit hook (`.git/hooks/pre-commit.old-macbook`): it
  pointed at a Python virtualenv on the old Intel MacBook that no longer exists.

## Original state (baseline, 2026-10-15)

As found at the start of the rebuild, before `05f08e1`. Upstream was `b6f7cbf`.

- Built in 2023–24 with generative AI assistance on an older Intel MacBook;
  `README.AWS.md` credits xAI Grok.
- Local, uncommitted work in progress: the EKS module was mid-refactor from
  multiple clusters (`cluster_names`, `for_each`) to one per environment;
  prod was updated, dev was not and failed `terraform validate`.
- `aws/scripts/cleanup_aws_2.sh` (untracked) had a bash syntax error and
  deleted every `bluedragon*` bucket without confirmation, including state.
- Binary saved plans (`plan-dev`, `plan-prod`, `bootstrap-*`, `bucket-*`) were
  committed; `.gitignore` pattern `*plan` did not match them.
- AWS access key IDs appeared in driftctl output under `single_instance/docs`
  and `single_instance/logs` (still present in git history; key since revoked).
- Hardcoded account `084375569056`, user `bluedragon`, key path
  `~/.aws/bluedragon.pem` across modules, tfvars and ecommerce-k8s.
- AWS provider pinned to 5.x (`5.94.1`, `~> 5.0`, `~> 5.95.0`).
- tfstate bootstrap encrypted buckets with a placeholder `key/dummy` KMS ARN.
- single_instance and tfstate/environments shared one state object per env.
- Prod EKS: version 1.28 with `t3.micro` nodes and an Amazon Linux 2 AMI lookup.

## Open items

- **EKS (blocks single_instance apply):** 1.28 is past AWS support; move to a
  current version, switch the node AMI lookup from Amazon Linux 2
  (`amazon-eks-node-*`, `/etc/eks/bootstrap.sh`) to Amazon Linux 2023
  (`nodeadm`), and raise prod nodes from `t3.micro` (dev uses `t3.medium`).
- **Suffixed tfstate buckets unused:** nothing stores state in
  `bluedragon-tfstate-admin-{env}-{suffix}`; candidates for removal, or fold
  the KMS key/alias into the bootstrap and drop the tfstate stage.
- **EC2 user data copies a private key** to the public instance (and into
  Terraform state). Replace with SSM Session Manager or an SSH agent forward.
- **ecommerce-k8s does not validate:** stage1 passes arguments its `vpc` and
  `eks` modules do not declare; stage2 defines providers and outputs twice.
  `stage2-k8s/statefile.json` (old Terraform state) is committed.
- **Docs:** `README.AWS.md` build steps predate the bootstrap/environments
  split; `aws/tfstate/README.md` is the accurate procedure.
- **Lock files:** git-ignored; consider committing multi-platform locks
  (`terraform providers lock -platform=darwin_arm64 -platform=linux_amd64`).
- **Pre-commit:** hook retired; reinstall from
  `single_instance/python3/requirements.txt` plus Homebrew tools if wanted
  (driftctl is archived upstream).
