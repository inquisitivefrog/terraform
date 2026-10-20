# az commands used in this repo

The Azure CLI (`az`) commands used to set up `azure/`, grouped by service,
with the closest gcloud and aws command beside each. Companion to
`../gcp/README.gcloud.md` and `../aws/README.aws.md`. Add rows as new
commands come into use.

Signed in as `dentaldanplateosaurus@outlook.com` (a personal Microsoft
account). Tenant `91737469-4965-4d2f-a72d-9ba8a531a355`.

Leave the default subscription on **`3caa5ec0-…`** (named "Azure
subscription 1" until the 2026-10-20 upgrade renamed it "Azure subscription
2"; refer to it by ID): it holds grid-meter's state (`grid-meter-app-tfstate-rg`),
used for interviews. This repo works in its own subscription, **`bluedragon-sre`**
(`8d75b8ef-999c-4f70-99a9-4eb0197f3a07`, pay-as-you-go, created 2026-10-20),
named explicitly in Terraform and passed as `--subscription` to az.

```sh
S=8d75b8ef-999c-4f70-99a9-4eb0197f3a07   # bluedragon-sre
```

## Helper scripts (`azure/scripts/`)

| Script | What it does |
|---|---|
| `register_providers.sh [extra…]` | Registers the resource providers this repo uses (tfstate and single_instance) in `bluedragon-sre` and waits until done. Run once per subscription, before the first apply; safe to re-run |
| `ssh_vm.sh dev\|prod [public\|private]` | SSH with `~/.ssh/bluedragon_azure`; private through public. `SSH_PORT=2222` uses the second port. `--run 'cmd'` runs a command through the Azure API instead (no SSH; works whatever the VPN does) |
| `vm_sizes.sh [max-vcpus] [region…]` | Lists VM sizes this subscription can actually use per region (not blocked, family quota > 0), with the regional vCPU quota. Default: <= 4 vCPUs in westus2, westus, westus3 |
| `check_resources.sh dev\|prod` | Confirms every tfstate resource exists and is configured as intended (dev: 18 bootstrap + 20 environments = 38). Exit 1 on any failure |
| `estimate_costs.sh [days]` | List-price estimate from live resources, plus real billed cost by service from Cost Management (lags a day or two; a new subscription reports nothing for up to 48 hours) |

## How Azure is organized (compared with GCP and AWS)

| Azure | What it is | GCP | AWS |
|---|---|---|---|
| Tenant (Microsoft Entra ID, formerly Azure AD) | The directory of users, groups and app identities | Organization + Cloud Identity | Organization + IAM Identity Center |
| Management group | Optional folders of subscriptions, for policy | Folder | Organizational unit |
| **Subscription** | Billing and isolation boundary; holds everything | **Project** | **Account** |
| **Resource group** | Required container for resources; deleting it deletes everything inside | none (labels) | none (tags) |
| Region (`westus2`) | Location; some resources are global | Region (`us-west1`) | Region (`us-west-2`) |
| Resource provider (`Microsoft.Storage`) | A service's API; registered per subscription | API (`storage.googleapis.com`), enabled per project | always on |
| Role assignment (RBAC) | Role + principal + scope (subscription, group or resource) | IAM binding | IAM policy attachment |
| Managed identity | An identity Azure manages for a resource | Service account | IAM role for a service |
| Service principal | An app's identity in the tenant | Service account | IAM user/role for an app |

Billing: a **billing account** (yours is an individual Microsoft Customer
Agreement) has **billing profiles** (an invoice) with **invoice sections**;
each subscription sits in one invoice section.

Tips:

- `--query '…'` filters output with JMESPath, like aws; `-o table|tsv|json|yaml`
  sets the format (`tsv` suits scripts).
- `--subscription <name-or-id>` targets a subscription without changing the default.
- `az <group> <command> --help` shows the manual; `az find "<words>"` searches examples.
- az 2.91 prints harmless Python `SyntaxWarning` lines on some commands; add
  `2>/dev/null` to hide them.

## Install and sign in

| Command | What it does | gcloud | aws |
|---|---|---|---|
| `az version` | Shows the CLI version (2.91.0 here) | `gcloud version` | `aws --version` |
| `az login` | Signs in through the browser | `gcloud auth login` | `aws configure` / `aws sso login` |
| `az account show` | Shows the current subscription, tenant and user | `gcloud config list` | `aws sts get-caller-identity` |
| `az account list --refresh -o table` | Lists subscriptions you can use (refresh picks up new ones) | `gcloud projects list` | `aws organizations list-accounts` |
| `az account set --subscription NAME` | Changes the default subscription (**don't**, see above) | `gcloud config set project` | `export AWS_PROFILE=…` |

Terraform's azurerm provider uses the az login by default; no separate step
like gcloud's `application-default login` is needed.

**MFA is mandatory** for user sign-ins to the CLI, PowerShell, IaC tools
(Terraform) and the SDKs (Microsoft's rollout, announced in the portal
2026-10). For a personal Microsoft account, turn it on at
https://account.microsoft.com/security → Advanced security options →
Two-step verification (Authenticator app or passkey), then run `az login`
again. Terraform reuses that session. Service principals and managed
identities are exempt, which matters only for future automation such as CI.

## Billing and subscriptions

| Command | What it does | gcloud |
|---|---|---|
| `az storage account check-name --name NAME --subscription <id> --query nameAvailable` | Checks a storage account name is free across all of Azure (needs `Microsoft.Storage` registered in that subscription) | |
| `az billing account list -o json` | Shows billing accounts and their agreement type (MCA, Individual) | `gcloud billing accounts list` |
| Portal: Subscriptions → **+ Add** → Plan "Microsoft Azure Plan" | Creates a subscription (walkthrough below) | `gcloud projects create` + `billing projects link` |

Creating the `bluedragon-sre` subscription (portal, 2026-10-20):

1. https://portal.azure.com → search **Subscriptions** → **+ Add**.
2. Basics: name `bluedragon-sre`; billing account, billing profile and
   invoice section are preselected; plan **Microsoft Azure Plan**.
3. Advanced: keep the same directory (tenant), management group and owner.
4. **Review + create** → **Create**. Then `az account list --refresh -o table`.

If **+ Add** is missing or a limit error appears, the account may be on a
trial or capped at one subscription: Help + support → "Service and subscription
limits (quotas)" → "Subscription limit".

**Free trial (found 2026-10-20):** `Azure subscription 1` is a free trial
(`FreeTrial_2014-09-01`, spending limit on, $200 credit, 30 days), ending
2026-10-22. A trial can't add subscriptions, and when it ends the
subscription is disabled: services stop and data (grid-meter's state account
included) is held about 90 days until upgraded. Upgrade: portal → Subscriptions
→ Azure subscription 1 → **Upgrade** → support plan Basic (free). The ID and
contents stay the same; the spending limit goes away, so add a budget alert.

Upgraded 2026-10-20: now `PayAsYouGo_2014-09-01`, spending limit off, same
ID; the portal renamed it "Azure subscription 2". Remaining trial credit
($199.09) still applies until 2026-10-22. The portal created a $200/month
budget (alerts only; it doesn't stop spending).

| Command | What it does |
|---|---|
| `az rest --method get --url "https://management.azure.com/subscriptions/<id>?api-version=2022-12-01" --query subscriptionPolicies` | Shows the offer (`quotaId`, e.g. `FreeTrial_2014-09-01`, `PayAsYouGo_2014-09-01`) and whether a spending limit is on |
| `az account tenant list` | Lists directories (tenants) your login can see; a separate signup can create a new one |
| `az account list --refresh --all -o table` | Lists every subscription, including disabled ones |

## Resource groups and resources

| Command | What it does | gcloud |
|---|---|---|
| `az group list -o table` | Lists resource groups | none |
| `az resource list --query 'length(@)'` | Counts every resource in the subscription | `gcloud asset search-all-resources` |
| `az resource list -g GROUP -o table` | Lists resources in one group | |
| `az group delete -n GROUP` | Deletes a group and **everything in it** (prompts first) | |

`NetworkWatcherRG` appears on its own the first time a virtual network is
created in a region; Azure manages it.

## VM sizes and quotas

| Command | What it does | gcloud |
|---|---|---|
| `az vm list-skus --location westus2 --resource-type virtualMachines --subscription $S` | Lists sizes; `restrictions` shows `NotAvailableForSubscription` for blocked ones | `gcloud compute machine-types list --zones=…` |
| `az vm list-usage --location westus2 --subscription $S -o table` | vCPU quotas: regional (`cores`) and per family | `gcloud compute regions describe` (quotas) |

Found 2026-10-20: the new subscription is blocked from B-series (and most
older families) in westus2, westus, westus3, centralus and eastus2; v6/v7
families are open with 10 vCPUs each and 10 per region. Smallest usable:
`Standard_F1als_v7` (1 vCPU, 2 GB) and `Standard_D2als_v7` (2 vCPU, 4 GB).
Quota increases: portal → Quotas → Compute.

## VMs, networking and SSH

| Command | What it does | gcloud |
|---|---|---|
| `az vm list -g RG --subscription $S -d -o table` | Lists VMs with power state and IPs | `gcloud compute instances list` |
| `az vm run-command invoke -g RG -n VM --command-id RunShellScript --scripts 'cmd' --subscription $S` | Runs a shell command on the VM through the Azure API (no SSH) | `gcloud compute ssh … --command` |
| `az vm boot-diagnostics get-boot-log -g RG -n VM --subscription $S` | Serial/boot log, including cloud-init | `gcloud compute instances get-serial-port-output` |
| `ssh -i ~/.ssh/bluedragon_azure azureuser@<public-ip>` | SSH to the public VM (key-based; personal accounts can't use Entra SSH login). A timeout usually means `curl -4 ifconfig.me` no longer matches `my_laptop_cidr_block` (see the Azure STATUS.md open items) | `gcloud compute ssh` |
| `az network nsg rule list -g RG --nsg-name nsg-public-vm-dev -o table` | Lists NSG rules | `gcloud compute firewall-rules list` |
| `az network nic list-effective-nsg -g RG -n nic-public-vm-dev` | Rules actually applied to a NIC | |
| `az network nic show-effective-route-table -g RG -n nic-public-vm-dev -o table` | Routes actually applied to a NIC (system defaults plus any route table) | `gcloud compute routes list` |
| `az network watcher test-ip-flow -g RG --vm VM --direction Inbound --protocol TCP --local <vm-ip>:22 --remote <your-ip>:50000` | Says whether the NSG allows a flow, and which rule decides. It only checks the IP you pass: compare `curl -4 ifconfig.me` with `my_laptop_cidr_block` first (PIA on and off give different IPs) | Connectivity Tests |
| `az network nic show -g RG -n nic-public-vm-dev --query '{accel:enableAcceleratedNetworking,ipconf:ipConfigurations[].publicIPAddress.id}'` | Accelerated networking and the public IP attached to a NIC | `gcloud compute instances describe` |
| `az vmss list -g MC_… --query '[].{n:name,accel:virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].enableAcceleratedNetworking}'` | Same for AKS nodes (scale set in the `MC_` resource group; `az network nic list` doesn't show them) | |
| `az network public-ip list -g RG -o table` | Public IPs (VM, NAT gateway) | `gcloud compute addresses list` |
| `az network nat gateway show -g RG -n nat-dev` | NAT gateway | `gcloud compute routers nats describe` |
| `az storage blob list --account-name bdsilogs… --container-name insights-logs-flowlogflowevent --auth-mode login` | VNet flow log files (can take 10+ minutes to appear) | `gcloud logging read` |

`list-effective-nsg` also lists a `networkManager` entry
(`adminNetworkSecurityGroups/_…`) with no rules. The subscription has no
Virtual Network Manager (`az network manager list` is empty), so it's a
platform default, not a hidden block. That command auto-installs the
`virtual-network-manager` az extension on first use.

## AKS

| Command | What it does | gcloud |
|---|---|---|
| `az aks get-credentials -g RG -n CLUSTER --subscription $S --admin --file ~/.kube/azure-dev` | Admin kubeconfig in its own file (`terraform output kubeconfig_command`) | `gcloud container clusters get-credentials` |
| `az aks get-credentials … --file F` then `kubelogin convert-kubeconfig -l azurecli` | Entra ID kubeconfig (Azure RBAC decides access); needs `kubelogin` (`brew install Azure/kubelogin/kubelogin`) | `gke-gcloud-auth-plugin` |
| `az aks show -g RG -n CLUSTER --query '{version:currentKubernetesVersion,state:provisioningState}'` | Cluster version and state | `gcloud container clusters describe` |
| `az aks nodepool list -g RG --cluster-name CLUSTER -o table` | Node pools | `gcloud container node-pools list` |
| `az aks get-versions --location westus2 -o table` | Versions available | `gcloud container get-server-config` |
| `az role assignment list --scope <cluster-id>/namespaces/app1 -o table` | Who may do what in a namespace (Azure RBAC for Kubernetes) | |

On the VM, its identity signs in with `az login --identity`, then
`az aks get-credentials` + `kubelogin convert-kubeconfig -l azurecli`.

## Tearing down single_instance

`terraform plan -destroy -out plan-dev`, then `terraform apply plan-dev`
(about 100 resources). Dev on 2026-10-20 took about 40 minutes:
Container Apps environment 21 minutes, AKS 5, Managed Redis 4, private
endpoint and DNS links about 2 each.

| Command | What it does | gcloud |
|---|---|---|
| `az containerapp env show -g RG -n cae-dev --query properties.provisioningState -o tsv` | `ScheduledForDelete` while Azure works through a slow environment delete (normal; its `ME_…` group goes first) | |
| `kubectl --kubeconfig ~/.kube/azure-dev get nodes` | `NotReady` during a destroy means the nodes lost their NAT path to the API server | `kubectl get nodes` |
| `kubectl --kubeconfig ~/.kube/azure-dev get ns app1 -o jsonpath='{range .status.conditions[*]}{.type}={.status}: {.message}{"\n"}{end}'` | Why a namespace is stuck in `Terminating` | same |
| `kubectl --kubeconfig ~/.kube/azure-dev delete pods --all -n app1 --force --grace-period=0` | Clears pods stuck `Terminating` on dead nodes (teardown only) | same |
| `kubectl … get ns app1 -o json \| jq '.spec.finalizers=[]' \| kubectl … replace --raw /api/v1/namespaces/app1/finalize -f -` | Finishes an already-empty namespace when discovery fails (`metrics.k8s.io` unreachable) | same |
| `az group list --subscription $S -o table` | After a destroy: only the `bluedragon-tfstate-*` groups should remain | `gcloud projects list` |

If a destroy fails with `Kubernetes delete error … timeout: 5m0s` on the
namespaces, run `plan -destroy` and `apply` again: refresh drops what is
already gone and the rest continues. Before 2026-10-20 the NAT gateway lost
its public IP first, causing exactly that; `modules/vpc/outputs.tf` now
makes destroy remove AKS before the NAT's public IP (not yet tested).

When the laptop IP changes, a full plan can't read the Kubernetes resources
(the AKS API only allows the old IP). Apply the new `my_laptop_cidr_block`
with `-target=module.aks.azurerm_kubernetes_cluster.this
-target=module.networking.azurerm_network_security_group.public_vm` first.

## Managed Redis, Container Apps, Service Bus

| Command | What it does | gcloud |
|---|---|---|
| `az redisenterprise show -g RG -n redis-bluedragon-dev-<suffix>` | Managed Redis (needs `az extension add -n redisenterprise`) | `gcloud redis instances describe` |
| `REDISCLI_AUTH=<key> redis-cli -h <hostname> -p 10000 --tls PING` | From the private VM: TLS + key (`terraform output -raw redis_access_key`) | |
| `az containerapp show -g RG -n nginx-dev --query properties.configuration.ingress.fqdn` | Container app's internal address | `gcloud run services describe` |
| `az containerapp env show -g RG -n cae-dev` | Environment (internal load balancer, subnet) | |
| `az servicebus topic list -g RG --namespace-name sb-bluedragon-dev-<suffix> -o table` | Topics | `gcloud pubsub topics list` |
| `az servicebus topic subscription show -g RG --namespace-name … --topic-name example-topic -n example-sub --query countDetails` | Message counts waiting in a subscription | |

## Cost Management

| Command | What it does | gcloud / aws |
|---|---|---|
| `az rest --method post --uri "https://management.azure.com/subscriptions/$S/providers/Microsoft.CostManagement/query?api-version=2023-11-01" --body '{"type":"ActualCost","timeframe":"MonthToDate","dataset":{"granularity":"None","aggregation":{"totalCost":{"name":"PreTaxCost","function":"Sum"}}}}'` | Real billed cost (no export setup needed, unlike GCP) | `aws ce get-cost-and-usage` |
| `az monitor metrics list --resource <storage-account-id> --metric UsedCapacity` | Bytes stored in a storage account | |

A brand-new subscription answers "doesn't have valid WebDirect/AIRS offer
type" until Cost Management picks it up (up to 48 hours).

## Storage, Key Vault, Event Grid

| Command | What it does | gcloud |
|---|---|---|
| `az storage account show -g RG -n ACCOUNT --subscription $S` | Shows settings: `allowSharedKeyAccess`, `minimumTlsVersion`, `encryption.keySource` | `gcloud storage buckets describe` |
| `az storage container show --name tfstate --account-name ACCOUNT --auth-mode login --subscription $S` | Shows a container using your Entra ID login (shared keys are off) | |
| `az storage blob list --container-name tfstate --account-name ACCOUNT --auth-mode login -o table` | Lists state blobs | `gcloud storage ls -r` |
| `az storage account management-policy show -g RG --account-name ACCOUNT` | Shows lifecycle rules | |
| `az monitor diagnostic-settings list --resource <account-id>/blobServices/default` | Shows where access logs go | |
| `az keyvault show -n VAULT --subscription $S` | Shows purge protection and RBAC mode | `gcloud kms keyrings describe` |
| `az keyvault key show --vault-name VAULT -n state-key` | Shows a key | `gcloud kms keys describe` |
| `az keyvault key rotation-policy show --vault-name VAULT -n state-key` | Shows the rotation schedule | |
| `az keyvault list-deleted --subscription $S` | Lists soft-deleted vaults (names held until purge date) | |
| `az eventgrid system-topic list --subscription $S -o table` | Lists blob event topics | `gcloud pubsub topics list` |

## Providers and access

| Command | What it does | gcloud |
|---|---|---|
| `az provider list --query "[?registrationState=='Registered'].namespace" -o tsv` | Lists registered resource providers | `gcloud services list --enabled` |
| `az provider register -n Microsoft.Storage --subscription $S` | Registers a provider (`register_providers.sh` does all of ours). azurerm 5.x does **not**: without it, creating a storage account fails with `MissingSubscriptionRegistration` | `gcloud services enable` |
| `az provider show -n Microsoft.Storage --subscription $S --query registrationState -o tsv` | `Registered`, `Registering` or `NotRegistered` | `gcloud services list --enabled` |
| `az role assignment list --all --assignee <object-id> -o table` | Lists your role assignments | `gcloud projects get-iam-policy` |
| `az ad signed-in-user show --query id -o tsv` | Gets your object ID, for `--assignee` above | |

For a personal Microsoft account, `--assignee <email>` fails ("Cannot find
user … in graph database") because the account is a guest-style identity in
its tenant; use the object ID from `az ad signed-in-user show` instead:

```sh
OID=$(az ad signed-in-user show --query id -o tsv)   # 6970ec35-… for this account
az role assignment list --all --assignee "$OID" -o table
# Owner  /subscriptions/3caa5ec0-…   (Azure subscription 1)
```
