# Status: Azure Terraform port

Rolling record of the Azure port. Add new entries at the top of the change
log, and update "Current state" and "Open items" when they change.

- Subscription: `bluedragon-sre` (`8d75b8ef-999c-4f70-99a9-4eb0197f3a07`),
  pay-as-you-go, created 2026-10-20
- Tenant: Default Directory (`91737469-4965-4d2f-a72d-9ba8a531a355`)
- Account: `dentaldanplateosaurus@outlook.com` (personal Microsoft account; MFA required)
- Regions: dev = `westus2`, prod = `westus`
- Terraform 1.13.2: azurerm `~> 5.10`, random `~> 3.9`, time `~> 0.14`

## Remember

- **Never use subscription `3caa5ec0-…` for this repo.** It's the az CLI
  default and holds grid-meter's Azure state (`grid-meter-app-tfstate-rg`),
  used for interviews. Don't `az account set` away from it; this repo names
  `bluedragon-sre` in every provider and backend.
- `3caa5ec0-…` was a free trial; upgraded to pay-as-you-go 2026-10-20 (renamed
  "Azure subscription 2"), so grid-meter's state isn't disabled on 2026-10-22.

## Current state (2026-10-20)

| Layer | dev (westus2) | prod (westus) |
|---|---|---|
| `tfstate/bootstrap` (local state) | **applied** 2026-10-20: `bdtfstatedev`, `bdtflogsdev`, budget; `check_resources.sh dev` 18/18 | **applied** 2026-10-20: `bdtfstateprod`, `bdtflogsprod`; 17/17 |
| `single_instance` (state in the CMK environments account, key `single_instance/terraform.tfstate`) | **destroyed** 2026-10-20 (was suffix `kwtq7q1d`); state empty. Key Vault `bdsikvdevkwtq7q1d` soft-deleted until 2026-10-27 (free) | written, validates; not planned |
| `tfstate/environments` (state in bootstrap account) | **applied** 2026-10-20, suffix `a2oowcjc`: vault `bdtfkvdeva2oowcjc`, state `bdtfstatedeva2oowcjc` (CMK); `check_resources.sh dev` 38/38 | **applied** 2026-10-20, suffix `gw3jhawh`: vault `bdtfkvprodgw3jhawh`, state `bdtfstateprodgw3jhawh` (CMK); 37/37 |

## Change log

### 2026-10-20: port `single_instance` to Azure

- `azure/scripts/vm_sizes.sh`: the subscription can't use B-series (or most
  older families) in westus2, westus, westus3, centralus or eastus2; v6/v7
  are open (10 vCPUs each, 10 per region). Sizes: VMs `Standard_F1als_v7`,
  AKS nodes `Standard_D2als_v7`.
- `register_providers.sh` now also registers Network, Compute,
  ContainerService, Cache, App, OperationalInsights, ServiceBus (done).
- Added `azure/single_instance` (mapping in its README). azurerm 5.x
  differences hit: private DNS resources take `private_dns_zone_id`, AKS
  needs `node_provisioning_profile`, Event Grid uses `service_bus_topic_id`.
- New SSH key `~/.ssh/bluedragon_azure` (ed25519) for the VMs.
- Dev plan: 100 to add.
- Dev apply 1: all but the Container Apps environment (azurerm 5.x needs
  `logs_destination = "log-analytics"`). Flow logs into a keys-off account
  worked. Apply 2: 18 added, 2 changed; replan clean.
- Flow-log retention policy removed: it made Azure add its own rule to the
  logs account's lifecycle policy, which Terraform then fought.
- Verified through `az vm run-command` (`azure/scripts/ssh_vm.sh --run`):
  both VMs bootstrapped; Redis resolves to the private endpoint (10.1.5.4),
  TLS + key PONG, NOAUTH without; the public VM's identity gets AKS
  credentials, sees 30 running pods, cluster-admin via Azure RBAC.
- Container app unreachable from the public VM: its NSG didn't allow the
  apps subnet (10.1.6.0/27). Fix planned (1 in-place NSG change).
- Fixed: public VM NSG now allows the apps subnet; container app returns
  200 from the public VM (first request after scale-to-zero is slow).
  Added Storage Blob Data Reader for you on the dev and logs accounts.
- SSH to the public VM: **fixed** 2026-10-20. Cause: `my_laptop_cidr_block`
  was the PIA exit IP (50.117.36.219) while the laptop connected from home
  (23.93.161.67, PIA off). Earlier, with PIA on, PIA itself interfered with
  SSH; a temporary NSG rule for the home IP was probably tested before it
  took effect. Ruled out on the way: effective routes (defaults),
  public IP <-> NIC association, sshd (22 and 2222), host firewall (none),
  the v7 MANA NIC (`ens1` bonded to `eth0`; accelerated networking shows
  false in ARM but the size supports it, and traffic flows), the empty
  `networkManager` admin NSG entry (platform default), laptop and ISP
  (github.com:22 and the AKS ingress reachable).
- Applied the new laptop IP with a targeted apply: a full plan fails
  reading the `app1`/`app2` namespaces because the AKS API still only
  allowed the old IP. `terraform plan -out plan-dev
  -target=module.aks.azurerm_kubernetes_cluster.this
  -target=module.networking.azurerm_network_security_group.public_vm`, then
  apply: 2 changed. `ssh_vm.sh dev` and `ssh_vm.sh dev private` (through
  the public VM) both log in (Ubuntu 24.04.5).
- Full (untargeted) dev plan afterwards: no changes.
- **Dev destroy (102 resources): the `app1`/`app2` namespaces were blocked.**
  Terraform removed the NAT gateway's public IP association in the first
  seconds, so the AKS nodes lost their path to the API server and went
  NotReady; pods stayed Terminating and namespace finalization waited on the
  unreachable metrics.k8s.io API. Unblocked by force-deleting the four pods
  and clearing the emptied namespaces' finalizers (`kubectl replace --raw
  /api/v1/namespaces/<ns>/finalize`). Fix (uncommitted, takes effect on the
  next apply): `subnet_private_id` in `modules/vpc/outputs.tf` also depends
  on `azurerm_nat_gateway_public_ip_association.this`, so destroy removes
  the Kubernetes resources and AKS before the NAT's public IP.
- First destroy run: 75 destroyed, then failed on the two namespaces'
  5-minute delete timeout (they finished moments later). The Container Apps
  environment took 21m29s (`ScheduledForDelete` in Azure meanwhile). Second
  `plan -destroy`: 27 to destroy (namespaces dropped on refresh); AKS took
  4m53s; 27 destroyed, state empty. Only the four `bluedragon-tfstate-*`
  resource groups remain in the subscription.
- VNet flow logs record only the AKS nodes' NICs, nothing from the two
  v7 VMs (possibly a v7/Azure Boost limitation; unconfirmed).
- Not yet: single_instance checks in check_resources.sh, prod plan, commit.

### 2026-10-20: port `tfstate` to Azure

- Created subscription `bluedragon-sre` (portal), after upgrading the free
  trial that blocked adding subscriptions.
- Added `azure/tfstate` with the same layout as aws/gcp: `bootstrap`,
  `environments`, modules `keyvault`, `messages` (Event Grid), `storage`.
  Mapping in `../README.md`.
- Added `azure/README.az.md`.
- First bootstrap applies created the resource groups and the budget, then
  failed on the storage accounts: `MissingSubscriptionRegistration` for
  `Microsoft.Storage`. azurerm 5.x registers no providers itself, even ones
  listed in `resource_providers_to_register`. Added
  `azure/scripts/register_providers.sh` (Storage, KeyVault, ManagedIdentity,
  EventGrid, Insights, Consumption), ran it, and set
  `resource_provider_registrations = "none"` in every provider block.
- Re-applied both bootstraps (7 added each). Added `azure/scripts/
  check_resources.sh` and `estimate_costs.sh` (adapted from grid-meter-app's
  Azure scripts). Cost Management doesn't report a new subscription yet
  ("doesn't have valid WebDirect/AIRS offer type"), up to 48 hours.
- Dev environments applied (17 added; Key Vault creation took 2.5 minutes).
  `check_resources.sh dev` 38/38 after fixing two script bugs: the CLI's
  rotation-policy shape is flat (`action`, `timeAfterCreate`) and the CMK
  vault URI has no trailing slash. Estimate about $0.34/month per rotating key.
- Prod environments applied (17 added); `check_resources.sh prod` 37/37.
  Re-plan of all four roots: no changes.

## Open items

- **Next (2026-10-21): test `single_instance/environments/prod`** (westus;
  written and validates, never planned). Check `curl -4 ifconfig.me`
  against prod's `my_laptop_cidr_block` first. Then destroy, which also
  tests the NAT ordering fix (namespaces should delete without the
  5-minute timeout).
- **single_instance checks** not yet in `check_resources.sh`.
- **VNet flow logs** record nothing from the two v7 VMs (unconfirmed why).
- **Laptop IP drift:** the public VM NSG and AKS authorized IPs allow only
  `my_laptop_cidr_block` (23.93.161.67/32, home, PIA off, on 2026-10-20).
  When `curl -4 ifconfig.me` differs, update tfvars and apply with
  `-target=module.aks.azurerm_kubernetes_cluster.this
  -target=module.networking.azurerm_network_security_group.public_vm`
  first; a full plan can't read the Kubernetes resources until then.
- **Event Grid topics have no subscriber** (like SNS and Pub/Sub here).
- **Cost Management** not reporting the new subscription yet; re-run
  `azure/scripts/estimate_costs.sh` after 2026-10-22.

- **New subscriptions:** run `azure/scripts/register_providers.sh` before the
  first apply.
