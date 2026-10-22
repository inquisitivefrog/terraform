# Next session: start here

Updated 2026-10-21. Rolling records: `aws/tfstate/docs/STATUS.md`,
`gcp/tfstate/docs/STATUS.md`, `azure/tfstate/docs/STATUS.md`. Command guides:
`aws/README.aws.md`, `gcp/README.gcloud.md`, `azure/README.az.md`.

## Where things stand

| Cloud | State | Cost |
|---|---|---|
| AWS (account 084375569056) | Everything destroyed, tfstate layer too (`aws/scripts/aws_wipe.sh`) | $0 |
| GCP (project `bluedragon-sre-vuft1e`) | tfstate applied; single_instance built and destroyed in both envs | pennies (KMS keys) |
| Azure (subscription `bluedragon-sre`, `8d75b8ef-…`) | **Port done.** single_instance dev and prod built, verified, destroyed; tfstate layer destroyed. Subscription empty | $0 |

Azure leftovers, free: four soft-deleted Key Vaults purge themselves
2026-10-27 to 2026-10-29. The subscription can be cancelled in the portal if
it won't be reused.

## Lessons worth keeping (Azure)

- **SSH or kubectl timeouts usually mean laptop IP drift** (PIA on
  50.117.36.219, home 23.93.161.67). `check_resources.sh` now flags it
  ("NSG/AKS API allows this laptop"). Apply a new IP with
  `-target=module.aks.azurerm_kubernetes_cluster.this -target=module.networking.azurerm_network_security_group.public_vm`
  first; a full plan can't read the Kubernetes resources until then.
- **Destroy takes ~30-40 minutes**; the Container Apps environment alone ~21.
- **Teardown order**: single_instance, then tfstate/environments, then
  tfstate/bootstrap. Never destroy an environments root while its
  single_instance destroy is still running (its state lives there).
- **NAT ordering fix** (`modules/vpc/outputs.tf`) verified in prod; the dev
  namespace timeout it caused is retestable only in a dev destroy.

## Possible next work

- **AWS open items** (`aws/tfstate/docs/STATUS.md`): DeveloperPolicy and
  AdminPolicy cover only dev's instances; ElastiCache Redis has no TLS or
  AUTH; dev ALB controller lacks IRSA, subnet tags and a current chart;
  ecommerce-k8s never plan-tested; suffixed tfstate buckets unused.
- **GCP open items** (`gcp/tfstate/docs/STATUS.md`): destroy needs a second
  pass for the Cloud Run serverless IP; public VM disk 65% full; GKE version
  floats on REGULAR; key rings pile up.
- **Azure (if rebuilt)**: VMs boot with pending security updates (cloud-init
  `package_upgrade`); leftover "dev" names in prod resources; VNet flow logs
  record nothing from the v7 VMs.
- **Repo**: wire trivy/tflint into the checks (`docs/REPO_CHECKS.md`).

## Never touch

- Azure subscription `3caa5ec0-…` (az default, grid-meter's state). Don't
  `az account set`.
- GCP project `project-4c5a8821-…` (dairyfarm, grid-meter), AWS account
  184375956348 (grid-meter), and the `grid-meter-app-eks` kubeconfig context.
  These are live interview apps.
