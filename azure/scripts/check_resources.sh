#!/usr/bin/env bash
# Confirm every azure/tfstate and azure/single_instance resource exists and is
# configured as intended, by asking Azure directly rather than trusting
# "Apply complete".
# Usage: ./check_resources.sh dev|prod      (run from anywhere; read-only)
# Adapted from grid-meter-app's check-resources-azure.sh and this repo's
# gcp/scripts/check_resources.sh (same false-PASS guards).
# Checks bootstrap always; tfstate environments and single_instance once each
# has terraform outputs (skipped, not failed, when not applied).

set -uo pipefail

env=${1:-}
case "$env:$#" in
  dev:1 | prod:1) ;;
  *)
    echo "Usage: $0 dev|prod   (checks azure/tfstate and, if applied, azure/single_instance)" >&2
    exit 1
    ;;
esac

S=8d75b8ef-999c-4f70-99a9-4eb0197f3a07 # bluedragon-sre, never the az default
ROOT="$(cd "$(dirname "$0")/../tfstate" && pwd)"
SI_ROOT="$(cd "$(dirname "$0")/../single_instance" && pwd)"
BOOT_RG="bluedragon-tfstate-$env-rg"
BOOT_STATE="bdtfstate$env"
BOOT_LOGS="bdtflogs$env"
ME="$(az ad signed-in-user show --query id -o tsv 2>/dev/null)"

# terraform output -raw prints a multi-line warning to stdout on empty state
# tf_output_in <root> <name>; tf_output <name> reads azure/tfstate.
tf_output_in() {
  local val
  val="$(cd "$1/environments/$env" && terraform output -raw "$2" 2>/dev/null)"
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}
tf_output() { tf_output_in "$ROOT" "$1"; }

PASS=0
FAIL=0

# expect <label> <wanted> <command...>: PASS only if stdout equals <wanted>
# ("" never counts: az prints nothing for a missing resource with -o tsv).
expect() {
  local label="$1" want="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
  if [[ -n "$out" && "$out" == "$want" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: expected '$want', got '${out:-nothing}'"
    FAIL=$((FAIL + 1))
  fi
}

# check <label> <command...>: PASS on exit 0 with non-empty, non-null stdout
check() {
  local label="$1" out
  shift
  out="$("$@" 2>/dev/null)"
  if [[ $? -eq 0 && -n "$out" && "$out" != "None" && "$out" != "null" ]]; then
    echo "  PASS  $label: ${out//$'\n'/, }"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: not found"
    FAIL=$((FAIL + 1))
  fi
}

# storage_checks <label> <rg> <account> [cmk-vault]
storage_checks() {
  local label="$1" rg="$2" acct="$3" vault="${4:-}" id
  id="$(az storage account show -g "$rg" -n "$acct" --subscription "$S" --query id -o tsv 2>/dev/null)"
  expect "$label account" "Succeeded" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query provisioningState -o tsv
  expect "$label shared keys off" "false" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query allowSharedKeyAccess -o tsv
  expect "$label public blob access off" "false" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query allowBlobPublicAccess -o tsv
  expect "$label TLS" "TLS1_2" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query minimumTlsVersion -o tsv
  expect "$label versioning" "true" az storage account blob-service-properties show -g "$rg" --account-name "$acct" --subscription "$S" --query isVersioningEnabled -o tsv
  expect "$label tfstate container" "tfstate" az storage container show --name tfstate --account-name "$acct" --auth-mode login --subscription "$S" --query name -o tsv
  check "$label lifecycle rule" az storage account management-policy show -g "$rg" --account-name "$acct" --subscription "$S" --query "policy.rules[].name" -o tsv
  check "$label access logs setting" az monitor diagnostic-settings list --resource "$id/blobServices/default" --subscription "$S" --query "[].name" -o tsv
  expect "$label blob data role for you" "Storage Blob Data Contributor" az role assignment list --scope "$id" --assignee "$ME" --subscription "$S" --query "[?roleDefinitionName=='Storage Blob Data Contributor'] | [0].roleDefinitionName" -o tsv
  if [[ -n "$vault" ]]; then
    expect "$label CMK source" "Microsoft.Keyvault" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query encryption.keySource -o tsv
    expect "$label CMK vault" "https://$vault.vault.azure.net" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query encryption.keyVaultProperties.keyVaultUri -o tsv
  else
    expect "$label encryption" "Microsoft.Storage" az storage account show -g "$rg" -n "$acct" --subscription "$S" --query encryption.keySource -o tsv
  fi
}

echo "== azure/tfstate $env (subscription bluedragon-sre) =="

echo
echo "-- Providers --"
for ns in Microsoft.Storage Microsoft.KeyVault Microsoft.ManagedIdentity Microsoft.EventGrid Microsoft.Insights; do
  expect "$ns" "Registered" az provider show -n "$ns" --subscription "$S" --query registrationState -o tsv
done

echo
echo "-- Bootstrap ($BOOT_RG) --"
expect "Resource group" "Succeeded" az group show -n "$BOOT_RG" --subscription "$S" --query properties.provisioningState -o tsv
storage_checks "State" "$BOOT_RG" "$BOOT_STATE"
expect "Logs account" "Succeeded" az storage account show -g "$BOOT_RG" -n "$BOOT_LOGS" --subscription "$S" --query provisioningState -o tsv
if [[ "$env" == "dev" ]]; then
  check "Budget (subscription-wide)" az rest --method get --url "https://management.azure.com/subscriptions/$S/providers/Microsoft.Consumption/budgets/bluedragon-sre-monthly?api-version=2023-05-01" --query "properties.amount" -o tsv
fi

ENV_RG="$(tf_output resource_group_name)"
if [[ -z "$ENV_RG" ]]; then
  echo
  echo "-- Environments: no terraform outputs (not applied yet); skipped --"
else
  VAULT="$(tf_output key_vault_name)"
  ENV_STATE="$(tf_output state_account_name)"
  ENV_LOGS="$(tf_output logs_account_name)"
  echo
  echo "-- Environments ($ENV_RG) --"
  check "State blob in bootstrap account" az storage blob show --container-name tfstate --name tfstate/terraform.tfstate --account-name "$BOOT_STATE" --auth-mode login --subscription "$S" --query properties.lastModified -o tsv
  expect "Resource group" "Succeeded" az group show -n "$ENV_RG" --subscription "$S" --query properties.provisioningState -o tsv
  expect "Key Vault purge protection" "true" az keyvault show -n "$VAULT" --subscription "$S" --query properties.enablePurgeProtection -o tsv
  expect "Key Vault RBAC" "true" az keyvault show -n "$VAULT" --subscription "$S" --query properties.enableRbacAuthorization -o tsv
  expect "Key state-key enabled" "true" az keyvault key show --vault-name "$VAULT" -n state-key --subscription "$S" --query attributes.enabled -o tsv
  check "Key rotation policy" az keyvault key rotation-policy show --vault-name "$VAULT" -n state-key --subscription "$S" --query "lifetimeActions[?action=='Rotate'].timeAfterCreate" -o tsv
  check "Storage identity" az identity show -g "$ENV_RG" -n "bluedragon-tfstate-$env-storage" --subscription "$S" --query principalId -o tsv
  storage_checks "Suffixed state" "$ENV_RG" "$ENV_STATE" "$VAULT"
  expect "Suffixed logs account" "Succeeded" az storage account show -g "$ENV_RG" -n "$ENV_LOGS" --subscription "$S" --query provisioningState -o tsv
  expect "Event Grid system topic" "Succeeded" az eventgrid system-topic show -g "$ENV_RG" -n "bluedragon-tfstate-$env-events" --subscription "$S" --query provisioningState -o tsv
fi

SI_RG="$(tf_output_in "$SI_ROOT" resource_group_name)"
if [[ -z "$SI_RG" ]] || ! az group show -n "$SI_RG" --subscription "$S" -o none 2>/dev/null; then
  echo
  echo "-- single_instance: not applied; skipped --"
else
  AKS="$(tf_output_in "$SI_ROOT" aks_cluster_name)"
  SUFFIX="${AKS##*-}"
  SI_VAULT="$(tf_output_in "$SI_ROOT" key_vault_name)"
  SB="$(tf_output_in "$SI_ROOT" servicebus_namespace)"
  REDIS="$(tf_output_in "$SI_ROOT" redis_hostname)"
  REDIS="${REDIS%%.*}"
  PUB_IP="$(tf_output_in "$SI_ROOT" public_vm_ip)"
  MY_IP="$(curl -4 -s --max-time 5 ifconfig.me)"
  echo
  echo "-- single_instance ($SI_RG) --"
  for ns in Microsoft.Network Microsoft.Compute Microsoft.ContainerService Microsoft.Cache Microsoft.App Microsoft.OperationalInsights Microsoft.ServiceBus; do
    expect "$ns" "Registered" az provider show -n "$ns" --subscription "$S" --query registrationState -o tsv
  done
  expect "Resource group" "Succeeded" az group show -n "$SI_RG" --subscription "$S" --query properties.provisioningState -o tsv

  # Network: the laptop checks catch IP drift (PIA on/off) before SSH times out
  expect "VNet" "Succeeded" az network vnet show -g "$SI_RG" -n "vnet-main-$env" --subscription "$S" --query provisioningState -o tsv
  check "NAT gateway public IP" az network public-ip show -g "$SI_RG" -n "pip-nat-$env" --subscription "$S" --query ipAddress -o tsv
  expect "NAT gateway nat-$env on private subnet" "true" az network vnet subnet show -g "$SI_RG" --vnet-name "vnet-main-$env" -n private --subscription "$S" --query "ends_with(natGateway.id, '/nat-$env')" -o tsv
  expect "Public VM NSG allows this laptop" "$MY_IP/32" az network nsg rule show -g "$SI_RG" --nsg-name "nsg-public-vm-$env" -n laptop-ssh-http --subscription "$S" --query sourceAddressPrefix -o tsv
  expect "Flow log enabled" "true" az network watcher flow-log show --location "$(az group show -n "$SI_RG" --subscription "$S" --query location -o tsv)" -n "flowlog-vnet-$env" --subscription "$S" --query enabled -o tsv

  # Compute
  for vm in public private; do
    expect "VM $vm-vm-$env" "VM running" az vm show -d -g "$SI_RG" -n "$vm-vm-$env" --subscription "$S" --query powerState -o tsv
  done
  expect "Public VM IP matches output" "$PUB_IP" az vm show -d -g "$SI_RG" -n "public-vm-$env" --subscription "$S" --query publicIps -o tsv
  expect "Container Apps environment" "Succeeded" az resource show -g "$SI_RG" -n "cae-$env" --resource-type Microsoft.App/managedEnvironments --subscription "$S" --query properties.provisioningState -o tsv
  expect "Container Apps internal only" "true" az resource show -g "$SI_RG" -n "cae-$env" --resource-type Microsoft.App/managedEnvironments --subscription "$S" --query properties.vnetConfiguration.internal -o tsv
  expect "Container app nginx-$env" "Succeeded" az resource show -g "$SI_RG" -n "nginx-$env" --resource-type Microsoft.App/containerApps --subscription "$S" --query properties.provisioningState -o tsv

  # AKS
  expect "AKS state" "Succeeded" az aks show -g "$SI_RG" -n "$AKS" --subscription "$S" --query provisioningState -o tsv
  expect "AKS power" "Running" az aks show -g "$SI_RG" -n "$AKS" --subscription "$S" --query powerState.code -o tsv
  expect "AKS Azure RBAC" "true" az aks show -g "$SI_RG" -n "$AKS" --subscription "$S" --query aadProfile.enableAzureRbac -o tsv
  expect "AKS secrets encrypted with Key Vault" "true" az aks show -g "$SI_RG" -n "$AKS" --subscription "$S" --query securityProfile.azureKeyVaultKms.enabled -o tsv
  expect "AKS API allows this laptop" "$MY_IP/32" az aks show -g "$SI_RG" -n "$AKS" --subscription "$S" --query "apiServerAccessProfile.authorizedIpRanges[?@=='$MY_IP/32'] | [0]" -o tsv
  check "AKS node pool" az aks nodepool list -g "$SI_RG" --cluster-name "$AKS" --subscription "$S" --query "[].join('', [name, ' x', to_string(count), ' ', vmSize])" -o tsv

  # Data and messaging
  expect "Managed Redis" "Succeeded" az resource show -g "$SI_RG" -n "$REDIS" --resource-type Microsoft.Cache/redisEnterprise --subscription "$S" --query properties.provisioningState -o tsv
  expect "Managed Redis public access" "Disabled" az resource show -g "$SI_RG" -n "$REDIS" --resource-type Microsoft.Cache/redisEnterprise --subscription "$S" --query properties.publicNetworkAccess -o tsv
  expect "Redis private endpoint" "Succeeded" az network private-endpoint show -g "$SI_RG" -n "pe-redis-$env" --subscription "$S" --query provisioningState -o tsv
  expect "Service Bus" "Succeeded" az servicebus namespace show -g "$SI_RG" -n "$SB" --subscription "$S" --query provisioningState -o tsv
  expect "Service Bus SAS keys off" "true" az servicebus namespace show -g "$SI_RG" -n "$SB" --subscription "$S" --query disableLocalAuth -o tsv
  check "Service Bus topics" az servicebus topic list -g "$SI_RG" --namespace-name "$SB" --subscription "$S" --query "[].name" -o tsv
  expect "Event Grid system topic" "Succeeded" az eventgrid system-topic show -g "$SI_RG" -n "evgt-dev-storage-$env" --subscription "$S" --query provisioningState -o tsv

  # Keys and storage
  expect "Key Vault purge protection" "true" az keyvault show -n "$SI_VAULT" --subscription "$S" --query properties.enablePurgeProtection -o tsv
  expect "Key Vault RBAC" "true" az keyvault show -n "$SI_VAULT" --subscription "$S" --query properties.enableRbacAuthorization -o tsv
  check "Key Vault keys" az keyvault key list --vault-name "$SI_VAULT" --subscription "$S" --query "[].name" -o tsv
  for acct in "bdsidata$env$SUFFIX" "bdsilogs$env$SUFFIX"; do
    expect "Storage $acct" "Succeeded" az storage account show -g "$SI_RG" -n "$acct" --subscription "$S" --query provisioningState -o tsv
    expect "Storage $acct shared keys off" "false" az storage account show -g "$SI_RG" -n "$acct" --subscription "$S" --query allowSharedKeyAccess -o tsv
    expect "Storage $acct CMK" "Microsoft.Keyvault" az storage account show -g "$SI_RG" -n "$acct" --subscription "$S" --query encryption.keySource -o tsv
  done
fi

echo
echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or misconfigured."
  exit 1
fi
echo "All expected resources present and configured."
