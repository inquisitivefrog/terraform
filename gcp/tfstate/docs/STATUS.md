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
- **grid-meter's GCP deployment shares that default project** (source
  `java/apps/grid-meter-app/terraform/gcp`; names start `grid-meter-app`).
  Like dairyfarm, it's for interviews: never touch it from this repo.
- **kubectl for this repo's GKE clusters uses its own kubeconfig file**
  (`export KUBECONFIG=~/.kube/gcp-dev`), so `get-credentials` never edits
  `~/.kube/config`.

## Current state (2026-10-19)

| Layer | dev (us-west1) | prod (us-west2) |
|---|---|---|
| `tfstate/bootstrap` (local state) | **applied** 2026-10-19: `bluedragon-tfstate-admin-dev`, `-dev-logs` | **applied** 2026-10-19: `bluedragon-tfstate-admin-prod`, `-prod-logs` |
| `single_instance` (state in bootstrap bucket, prefix `single_instance`, CMEK `state-bucket-key`) | **destroyed** 2026-10-20 (was suffix `oaxxklen`); VPC + private subnet wait on Cloud Run's serverless IP release, then destroy finishes | **destroyed** 2026-10-20 (was suffix `c3pfltlz`); VPC + private subnet wait on Cloud Run's serverless IP release, then destroy finishes |
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
| `single_instance/environments/{env}` | `bluedragon-tfstate-admin-{env}` | `single_instance` | CMEK `state-bucket-key` |

## Change log

### 2026-10-20: port `aws/single_instance` to GCP

- Added `gcp/single_instance` (mapping in its README): VPC + Cloud NAT,
  firewall rules, 2 Ubuntu 24.04 VMs (OS Login), Cloud Run nginx,
  Memorystore Redis 7.2 (AUTH + TLS), zonal GKE with private nodes and CMEK
  secrets, per-env service accounts, KMS key ring, Pub/Sub topics, dev + log
  buckets, and the Kubernetes layer (dev only, as in AWS).
- Dev plan: 96 to add.
- Dev applied (96 added). Verified: 3 GKE nodes Ready (autoscaler added
  one), app1/app2 pods Running, ingress returns 200, `sre` RBAC limited to
  app1 pods/services, Cloud Run rejects internet traffic (404).
- Fixes after apply: firewall Redis egress used 6379, but Memorystore with
  TLS listens on 6378 (now taken from the instance); ignore autoscaler
  `node_count` and GKE's `neg-status` annotation, which showed as drift.
- SSH from the laptop times out: Private Internet Access (VPN, utun4)
  routes 0.0.0.0/1 and drops port 22 and ICMP while answering other ports
  itself. Firewall rules are correct. Added an IAP rule (35.235.240.0/20,
  tcp 22, public VM only); `gcloud compute ssh --tunnel-through-iap` works,
  and the private VM is reached through the public one.
- Redis verified from the private VM: TLS on 6378 with AUTH returns PONG;
  without AUTH, NOAUTH.
- VM kubectl was denied: without the `userinfo-email` scope GKE saw the
  service account's numeric ID, not its email, so the cluster-admin binding
  didn't match. Added the scope (VMs stop/start; public IP kept). On the VM,
  clear old cached tokens once: `rm ~/.kube/gke_gcloud_auth_plugin_cache`.
  Now `vm-dev@…` has cluster-admin.
- Added `gcp/scripts/kube_use.sh dev|prod` (kubeconfig in `~/.kube/gcp-<env>`;
  `~/.kube/config` untouched) and `gcp/scripts/ssh_vm.sh dev|prod
  [public|private]` (IAP; private through public). Both tested on dev.
- Added `project_id` and `zone` outputs for the scripts.
- Added `gcp/scripts/check_resources.sh dev|prod` and
  `gcp/scripts/estimate_costs.sh dev|prod|all`, adapted from grid-meter-app's
  check-resources-gcp.sh / estimate-costs-gcp.sh. Dev: 45 checks pass;
  estimate about $5.30/day ($160/month) at list price, GKE fee covered by the
  free credit (no clusters in the billing account's other projects).
- Prod plan: 79 to add (dev minus the 17 Kubernetes-layer resources).
- Prod applied (79 added); `check_resources.sh prod`: 38/38 pass.
  Estimate about $4.18/day ($127/month) once dev's cluster is gone and prod
  gets the free GKE credit.
- Prod destroyed after its checks (no Kubernetes layer, so one destroy);
  its VPC and subnet wait on the same serverless IP release as dev.
- Dev destroyed: Kubernetes layer first (`terraform destroy
  -target=module.kubernetes`), then waited for GKE to delete the ingress
  load balancer, NEGs and `k8s-*` firewall rules (left behind, they block
  deleting the VPC), then the rest. The VPC and private subnet failed: Cloud
  Run's direct VPC egress holds a `serverless-ipv4-cloudrun-*` address in
  the subnet, which GCP releases 1-2 hours after the service is deleted.
  Re-run `terraform destroy` once
  `gcloud compute addresses list --filter=purpose=SERVERLESS` is empty.

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

- **Laptop IP drift:** GKE authorized networks and the public VM firewall
  allow only `my_laptop_cidr_block` (50.117.36.219/32 on 2026-10-20).
- **Destroy order:** destroy `module.kubernetes` first and wait for the
  ingress load balancer to go; expect a second `terraform destroy` 1-2 hours
  later for the VPC (Cloud Run serverless IP release).
- **`default` network:** enabling the Compute API created the auto-mode
  `default` VPC with allow-SSH/RDP/ICMP-from-anywhere rules. Nothing uses it.
- **Public VM disk:** 10 GB is 65% used after the startup installs.
- **GKE version floats** on the REGULAR channel (AWS pinned 1.36).

- **Suffixed tfstate buckets unused** (carried over from AWS): nothing stores
  state in `bluedragon-tfstate-admin-{env}-{suffix}` yet.
- **Key rings pile up:** each rebuild leaves an empty key ring (free) behind.
