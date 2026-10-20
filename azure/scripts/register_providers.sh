#!/usr/bin/env bash
# Register the Azure resource providers this repo uses in the bluedragon-sre
# subscription (once per subscription; safe to re-run). Like enabling APIs in
# a GCP project. azurerm 5.x doesn't register them itself, and creating a
# storage account before Microsoft.Storage is registered fails with
# MissingSubscriptionRegistration.
# Usage: ./register_providers.sh [extra namespaces...]

set -euo pipefail

SUBSCRIPTION=8d75b8ef-999c-4f70-99a9-4eb0197f3a07 # bluedragon-sre, never the az default

namespaces=(
  Microsoft.Storage         # storage accounts
  Microsoft.KeyVault        # Key Vault keys (CMK)
  Microsoft.ManagedIdentity # user-assigned identities
  Microsoft.EventGrid       # blob event topics
  Microsoft.Insights        # diagnostic settings (access logs)
  Microsoft.Consumption     # budgets
  # single_instance
  Microsoft.Network            # VNets, NSGs, NAT gateway, private endpoints, flow logs
  Microsoft.Compute            # VMs, disks
  Microsoft.ContainerService   # AKS
  Microsoft.Cache              # Azure Managed Redis
  Microsoft.App                # Container Apps
  Microsoft.OperationalInsights # Log Analytics
  Microsoft.ServiceBus         # topics and subscriptions
  "$@"
)

state() {
  az provider show -n "$1" --subscription "$SUBSCRIPTION" --query registrationState -o tsv 2>/dev/null
}

for ns in "${namespaces[@]}"; do
  if [[ "$(state "$ns")" != "Registered" ]]; then
    echo "+ az provider register -n $ns"
    az provider register -n "$ns" --subscription "$SUBSCRIPTION" >/dev/null 2>&1
  fi
done

# Registration takes a minute or two
for _ in $(seq 1 60); do
  pending=()
  for ns in "${namespaces[@]}"; do
    [[ "$(state "$ns")" == "Registered" ]] || pending+=("$ns")
  done
  [[ ${#pending[@]} -eq 0 ]] && break
  sleep 10
done

for ns in "${namespaces[@]}"; do
  printf '  %-28s %s\n' "$ns" "$(state "$ns")"
done
[[ ${#pending[@]} -eq 0 ]] || { echo "Still pending: ${pending[*]}" >&2; exit 1; }
