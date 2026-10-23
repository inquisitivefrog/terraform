# Next session: start here

Updated 2026-10-23. Rolling records: `aws/tfstate/docs/STATUS.md`,
`gcp/tfstate/docs/STATUS.md`, `azure/tfstate/docs/STATUS.md`. Command guides:
`aws/README.aws.md`, `gcp/README.gcloud.md`, `azure/README.az.md`.

## Where things stand

| Cloud | State | Cost |
|---|---|---|
| AWS (account `650836812595`, profile `blue-elephant`, us-east-2; Free plan, credits to 2027-04-22) | Everything destroyed (checked 2026-10-23). single_instance dev and prod applied, verified and destroyed on 2026-10-22 | $0; budget `monthly-5usd` |
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

Done on 2026-10-22 (commits `2774441`, `b1a7fd9`): moved to the new account,
renamed `bluedragon` to `blue-elephant`, applied and verified groups 1 and 3
in dev and prod, fixed destroy ordering (aws-auth, Ingress), ECS crash loop
and log-group leftovers, then tore everything down.

Done on 2026-10-23 (uncommitted): ecommerce-k8s repointed, applied in the
new account (terraform-state 4, stage1 64, stage2 12), verified (app answered
through the ALB) and destroyed; account swept empty. Fixes from the run:
access-policy associations wait for their entries, `aws-auth` is patched
(`kubernetes_config_map_v1_data`), controller policy gained 3 EC2 read
actions, EKS log group now managed (untested). Also uncommitted: the
`aws_wipe.sh` preflight fix, doc updates, `.gitignore` plan names.

Then:
1. **Commit** the above once reviewed.
2. **datastore-clusters:** new `aws/datastore-clusters` tree; decide which
   datastores first. Free-plan limits: only Free Tier EC2 types; SCP denies
   IAM groups, login profiles and OIDC providers (use Pod Identity).
3. **Group 2** (dev ALB ingress): the controller never creates an ALB here;
   needs Pod Identity for the controller, subnet tags, a current chart.
4. **ecommerce-k8s clean-up:** see STATUS.md open items (check script untested live,
   Argo CD chart, upstream controller policy, tflint/trivy).
5. Later: make scanners blocking; regenerate module READMEs (terraform-docs).

Other clouds' open items: `gcp/tfstate/docs/STATUS.md`,
`azure/tfstate/docs/STATUS.md`.

## Never touch

- Azure subscription `3caa5ec0-…` (az default, grid-meter's state). Don't
  `az account set`.
- GCP project `project-4c5a8821-…` (dairyfarm, grid-meter), AWS account
  184375956348 (grid-meter), and the `grid-meter-app-eks` kubeconfig context.
  These are live interview apps.
