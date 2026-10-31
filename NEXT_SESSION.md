# Next session: start here

Updated 2026-10-30. Rolling records: `aws/tfstate/docs/STATUS.md`,
`gcp/tfstate/docs/STATUS.md`, `azure/tfstate/docs/STATUS.md`,
`private/docs/STATUS.md`. Command guides:
`aws/README.aws.md`, `gcp/README.gcloud.md`, `azure/README.az.md`.

## Where things stand

| Cloud | State | Cost |
|---|---|---|
| AWS (account `650836812595`, profile `blue-elephant`, us-east-2; Free plan, credits to 2027-04-22) | Everything destroyed (swept 2026-10-24 night; credits $137.41). single_instance verified and destroyed 2026-10-22; ecommerce-k8s verified (Argo CD GitOps, 34/34) and destroyed 2026-10-23 | $0; budget `monthly-5usd` |
| GCP (project `bluedragon-sre-vuft1e`) | tfstate applied; single_instance built and destroyed in both envs | pennies (KMS keys) |
| Private cloud (Docker Desktop + kind, `private/`) | `datastore-clusters`: platform, relational (pg 16.15, PXC 8.0.46, ~3 M orders each), orders app and the backup store (SeaweedFS, outside the cluster) applied; runbooks 1, 5, 13, 17, 23-26 pass. Backups (cert-manager, Barman Cloud plugin, PXC backup) written, not applied. **Stopped** with `docker_shutdown.sh`; resume list in `private/docs/STATUS.md` | $0 |
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

Done on 2026-10-23 (pushed, through `5532a03`): ecommerce-k8s in the new
account, deployed twice and verified with `scripts/check_resources.sh` (34/34).
Scanner fixes: tflint 0, trivy 1, KMS, flow logs, chart hardening. Dead code
removed. **Argo CD now deploys the app from this repo's `main`**: a pushed
chart change rolls out with no Terraform run. Helper scripts `kube_use.sh`,
`helm_status.sh` and `argocd_use.sh`. Teardown was clean, with no manual
steps.

Then (2026-10-23 evening) the **upgrade set**: Argo CD v3.5.6, load-balancer
controller v3.6.1, access-entries-only auth (`API`), RBAC cleanup. It was
deployed fresh and verified 36/36, and is committed.

Then:
1. **ecommerce-k8s:** done and destroyed (verified 37/37, zero-gap
   rollouts). Small follow-up: Ingress `deregistration_delay=30` (see
   STATUS.md, 2026-10-24 teardown).
2. **datastore-clusters: moved to the private cloud and widened** to the
   whole range of datastore categories (`private/datastore-clusters`; design
   and decisions in its `docs/DESIGN.md`; runbook definitions in
   `docs/RUNBOOKS.md`). Platform (kind `datastore-dev`, kube-prometheus-stack)
   and relational (`pg` PostgreSQL 16.13, `mysql` PXC 8.0.44) applied and
   verified 2026-10-26. Since then: the orders app and k6 load, runbooks
   1, 5, 13, 17, 23, 24, 25, 26 scripted and passing (expectations in
   `private/datastore-clusters/test_plans/`). **Next (2026-10-31): apply
   the backups** (`private/datastore-clusters/docs/BACKUPS.md`; steps in
   `private/docs/STATUS.md`, "Resume here"), then script runbooks 7, 8, 9
   (back up, restore, point in time). Dedicated database nodes deferred to the node-drain and
   node-replacement runbooks. Open questions are listed at the end of
   DESIGN.md. The AWS Aurora version was removed 2026-10-26 (design kept in
   `aws/tfstate/docs/STATUS.md`).
3. **ecommerce-k8s N+2:** 3 AZs, `replicaCount: 3` with zone
   `topologySpreadConstraints`, a PodDisruptionBudget; Ingress
   `deregistration_delay=30`.
4. **Group 2** (single_instance dev ALB ingress): copy ecommerce-k8s's
   working pattern (Pod Identity, current chart, upstream policy).
5. Later: make scanners blocking (KSV-0125 needs an ignore mechanism for
   Helm templates); regenerate module READMEs (terraform-docs).

Other clouds' open items: `gcp/tfstate/docs/STATUS.md`,
`azure/tfstate/docs/STATUS.md`.

## Never touch

- Azure subscription `3caa5ec0-…` (az default, grid-meter's state). Don't
  `az account set`.
- GCP project `project-4c5a8821-…` (dairyfarm, grid-meter), AWS account
  184375956348 (grid-meter), and the `grid-meter-app-eks` kubeconfig context.
  These are live interview apps.
