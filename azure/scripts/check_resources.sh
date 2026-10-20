#!/usr/bin/env bash
# Confirm every azure/tfstate resource exists and is configured as intended,
# by asking Azure directly rather than trusting "Apply complete".
# Usage: ./check_resources.sh dev|prod      (run from anywhere; read-only)
# Adapted from grid-meter-app's check-resources-azure.sh and this repo's
# gcp/scripts/check_resources.sh (same false-PASS guards).
# Checks bootstrap always, and environments once it has outputs.

set -uo pipefail

env=${1:-}
case "$env:$#" in
  dev:1 | prod:1) ;;
  *)
    echo "Usage: $0 dev|prod   (checks azure/tfstate only; takes no other arguments)" >&2
    exit 1
    ;;
esac

S=8d75b8ef-999c-4f70-99a9-4eb0197f3a07 # bluedragon-sre, never the az default
ROOT="$(cd "$(dirname "$0")/../tfstate" && pwd)"
BOOT_RG="bluedragon-tfstate-$env-rg"
BOOT_STATE="bdtfstate$env"
BOOT_LOGS="bdtflogs$env"
ME="$(az ad signed-in-user show --query id -o tsv 2>/dev/null)"

# terraform output -raw prints a multi-line warning to stdout on empty state
tf_output() {
  local val
  val="$(cd "$ROOT/environments/$env" && terraform output -raw "$1" 2>/dev/null)"
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}

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

echo
echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or misconfigured."
  exit 1
fi
echo "All expected resources present and configured."
