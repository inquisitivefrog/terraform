# Status: GCP Terraform port

Rolling record of the GCP port of `aws/tfstate`. Add new entries at the top
of the change log, and update "Current state" and "Open items" when they
change.

- Project: `bluedragon-sre-vuft1e` (number `581958729900`, "bluedragon sre"),
  org `dentaldanplateosaurus-org`, billing `011D61-08EF93-5C70B6`
- Account: `dentaldanplateosaurus@gmail.com`
- Regions: dev = `us-west1`, prod = `us-west2`
- Terraform 1.13.2: google provider `~> 8.7`, random `~> 3.9`

## Remember

- **Never use `project-4c5a8821-da4c-4c68-97f` for this repo.** That is the
  gcloud default project and hosts the live dairyfarm demo (Cloud Run +
  Cloud SQL, us-central1). Keep the gcloud default as is; this repo passes
  its project through `terraform.tfvars`, and gcloud commands here take
  `--project bluedragon-sre-vuft1e`.

## Current state (2026-10-19)

| Layer | dev (us-west1) | prod (us-west2) |
|---|---|---|
| `tfstate/bootstrap` (local state) | **applied** 2026-10-19: `bluedragon-tfstate-admin-dev`, `-dev-logs` | **applied** 2026-10-19: `bluedragon-tfstate-admin-prod`, `-prod-logs` |
| `tfstate/environments` (state in bootstrap bucket, prefix `tfstate`) | **applied** 2026-10-19, suffix `imtcz3jz` | **applied** 2026-10-19, suffix `6wtegjuq` |

KMS keys (`state_bucket_key_id` output; use as `kms_encryption_key` in later
roots' `backend.hcl`):

- dev: `projects/bluedragon-sre-vuft1e/locations/us-west1/keyRings/tfstate-dev-imtcz3jz/cryptoKeys/state-bucket-key`
- prod: `projects/bluedragon-sre-vuft1e/locations/us-west2/keyRings/tfstate-prod-6wtegjuq/cryptoKeys/state-bucket-key`

Pub/Sub topics `logging-topic-{dev,prod}` (CMEK `pubsub-logging-key`), no
subscriptions.

### Where state lives

| Root | Bucket | Prefix | Encryption |
|---|---|---|---|
| `tfstate/bootstrap/{env}` | local `terraform.tfstate` | — | — |
| `tfstate/environments/{env}` | `bluedragon-tfstate-admin-{env}` | `tfstate` | Google-managed |

## Change log

### 2026-10-19: environments applied

- `environments/dev` and `environments/prod` applied, 13 resources each;
  re-plan shows no changes.
- Verified: state at `gs://bluedragon-tfstate-admin-{env}/tfstate/default.tfstate`;
  suffixed state buckets default to `state-bucket-key`; topics use
  `pubsub-logging-key`; uploading a test object to the dev suffixed bucket
  published `OBJECT_FINALIZE` to `logging-topic-dev` (test object and
  temporary subscription removed).

### 2026-10-19: bootstrap applied

- Providers set `billing_project` + `user_project_override`: ADC's quota
  project is dairyfarm's, which lacks Cloud KMS and shouldn't carry this
  repo's quota.
- Org policies checked: no member-domain or location restrictions.
- `bootstrap/dev` and `bootstrap/prod` applied, 6 resources each (3 APIs,
  state bucket, logs bucket, usage-log writer grant).

### 2026-10-19: dedicated project

- Created project `bluedragon-sre-vuft1e` under the org, linked billing,
  enabled Storage, Cloud KMS, Pub/Sub, Resource Manager and Service Usage
  APIs. Keeps this repo apart from dairyfarm in the default project.
- Pointed all four `terraform.tfvars` at it.

### 2026-10-19: port `aws/tfstate` to GCP

- Added `gcp/tfstate` with the same layout as `aws/tfstate`: `bootstrap`,
  `environments` and the `kms`, `messages` and `storage` modules. See the
  mapping table in `../README.md`.
- Key ring name carries the random suffix because GCP key rings can't be
  deleted.

## Open items

- **Suffixed tfstate buckets unused** (carried over from AWS): nothing stores
  state in `bluedragon-tfstate-admin-{env}-{suffix}` yet.
- **Key rings pile up:** each rebuild leaves an empty key ring (free) behind.
