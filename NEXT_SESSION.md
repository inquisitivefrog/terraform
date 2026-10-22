# Next session: start here

Updated 2026-10-21 (evening). Rolling records: `aws/tfstate/docs/STATUS.md`,
`gcp/tfstate/docs/STATUS.md`, `azure/tfstate/docs/STATUS.md`. Command guides:
`aws/README.aws.md`, `gcp/README.gcloud.md`, `azure/README.az.md`.

## Where things stand

| Cloud | State | Cost |
|---|---|---|
| AWS (account 084375569056) | Everything destroyed; groups 1 and 3 changed in code, not yet applied | $0 (no free credits left; ~$4 billed in October) |
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

## Next: AWS

Groups 1 and 3 are done in code (committed, not applied); see
`aws/tfstate/docs/STATUS.md`, 2026-10-21 entry.

- Group 1 (security): Redis TLS + AUTH (replication group, 7.1), IAM
  policies by name pattern and `Project` tag, IMDSv2 on EKS nodes, flow logs
  KMS-encrypted.
- Group 3 (cleanup): tfstate/environments is now just the KMS key; unused
  declarations removed; lock files committed; tflint/trivy/checkov installed
  and wired in report-only; `aws/scripts/check_resources.sh` and
  `estimate_costs.sh`; README.AWS.md rewritten; `aws/README.aws.test.md`.

Then:
1. **Group 2:** dev ALB ingress: IRSA role + OIDC provider for the ALB
   controller, `kubernetes.io/role/elb` subnet tags, chart 1.6.0 to current,
   bigger dev nodes (t3.micro is full); fold in pod hardening (security
   context, no `:latest`) and EKS control-plane logging; gp2 to gp3.
2. **Decide how to deploy to confirm** (cheapest: dev only, same-day destroy;
   prod plan only works after dev's shared IAM exists). Verify with
   `aws/scripts/check_resources.sh dev`.
3. Later: ecommerce-k8s (group 4; tflint shows 40 issues); make scanners
   blocking once findings are fixed or accepted.

Other clouds' open items: `gcp/tfstate/docs/STATUS.md`,
`azure/tfstate/docs/STATUS.md`.

## Never touch

- Azure subscription `3caa5ec0-…` (az default, grid-meter's state). Don't
  `az account set`.
- GCP project `project-4c5a8821-…` (dairyfarm, grid-meter), AWS account
  184375956348 (grid-meter), and the `grid-meter-app-eks` kubeconfig context.
  These are live interview apps.
