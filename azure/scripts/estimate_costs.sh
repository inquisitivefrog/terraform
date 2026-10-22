#!/usr/bin/env bash
# What azure/ costs in the bluedragon-sre subscription, two ways:
#   1. Estimate: live inventory x list prices (like gcp/scripts/estimate_costs.sh).
#   2. Billed: real cost by service from Azure Cost Management (like
#      grid-meter-app's check-costs-azure.sh). Lags usage by a day or two,
#      so a same-day apply or teardown won't show yet.
# Usage: ./estimate_costs.sh [days-back]      (default 7; read-only)
#
# The tfstate layer costs cents: storage by the GB, Key Vault by the
# operation, Event Grid's first 100k operations a month free, budgets and
# managed identities free. The one fixed charge is automated key rotation.
# single_instance is where the money goes: VMs, AKS nodes, disks, NAT
# gateway, public IPs, load balancer, private endpoint, Managed Redis and
# Service Bus are priced per hour (or month) from the public Azure Retail
# Prices API (prices.azure.com, no sign-in), for the region each runs in.

set -uo pipefail

S=8d75b8ef-999c-4f70-99a9-4eb0197f3a07 # bluedragon-sre, never the az default
DAYS="${1:-7}"

# --- List prices, USD (sourced 2026-10-20) ---
BLOB_HOT_GB_MONTH=0.0184 # LRS hot, West US 2; West US is close
KEY_ROTATION=1.00        # per scheduled rotation (US page hides it; China's is ~$1)
ROTATION_DAYS=90         # state-key rotation_policy

calc() { awk "BEGIN{printf \"%.4f\", $1}"; }

echo "== bluedragon-sre: estimate from live resources (list price) =="
TOTAL=0

# Storage: bytes used per account, from Azure Monitor (hourly metric)
accounts="$(az storage account list --subscription "$S" --query '[].id' -o tsv 2>/dev/null)"
if [[ -z "$accounts" ]]; then
  echo "  (no storage accounts)"
fi
for id in $accounts; do
  bytes="$(az monitor metrics list --resource "$id" --metric UsedCapacity --interval PT1H \
    --subscription "$S" --query 'value[0].timeseries[0].data[-1].average' -o tsv 2>/dev/null)"
  bytes="${bytes:-0}"
  [[ "$bytes" == "None" ]] && bytes=0
  month="$(calc "$bytes/1073741824*$BLOB_HOT_GB_MONTH")"
  printf "  %-46s %10.0f bytes   \$%7.4f/mo\n" "storage ${id##*/}" "$bytes" "$month"
  TOTAL="$(calc "$TOTAL+$month")"
done

# Key Vault keys with automatic rotation
for vault in $(az keyvault list --subscription "$S" --query '[].name' -o tsv 2>/dev/null); do
  for key in $(az keyvault key list --vault-name "$vault" --subscription "$S" --query '[].name' -o tsv 2>/dev/null); do
    days="$(az keyvault key rotation-policy show --vault-name "$vault" -n "$key" --subscription "$S" \
      --query "lifetimeActions[?action=='Rotate'].timeAfterCreate | [0]" -o tsv 2>/dev/null | tr -dc '0-9')"
    [[ -z "$days" ]] && continue
    month="$(calc "$KEY_ROTATION*30.4/$days")"
    printf "  %-46s %10s         \$%7.4f/mo\n" "key rotation $vault/$key" "every ${days}d" "$month"
    TOTAL="$(calc "$TOTAL+$month")"
  done
done

# --- Running resources (single_instance), hourly list prices x 730 h ---
RETAIL='https://prices.azure.com/api/retail/prices'
HOURS=730
PRIVATE_ENDPOINT_HOUR=0.01 # not in the Retail Prices API; azure.microsoft.com/pricing/details/private-link
declare -A PRICE_CACHE=()

# retail <OData filter> [jq select]: first Consumption price matching, cached
retail() {
  local key="$1|${2:-}"
  if [[ -z "${PRICE_CACHE[$key]+x}" ]]; then
    PRICE_CACHE[$key]="$(curl -s -G "$RETAIL" --data-urlencode "\$filter=$1" |
      jq -r "[.Items[] | select(.type==\"Consumption\") ${2:-}] | .[0].retailPrice // empty" 2>/dev/null)"
  fi
  printf '%s' "${PRICE_CACHE[$key]}"
}

# line <label> <detail> <monthly or empty>
line() {
  if [[ -z "$3" ]]; then
    printf "  %-46s %10s   (price not found)\n" "$1" "$2"
    return
  fi
  printf "  %-46s %10s   \$%7.2f/mo\n" "$1" "$2" "$3"
  TOTAL="$(calc "$TOTAL+$3")"
}

LINUX_ONDEMAND='| select((.productName|test("Windows")|not) and (.skuName|test("Spot|Low Priority")|not))'

# VMs (running only; a deallocated VM costs only its disk)
while IFS=$'\t' read -r name size loc power; do
  [[ -z "$name" ]] && continue
  if [[ "$power" != "VM running" ]]; then
    line "vm $name ($size)" "${power#VM }" 0
    continue
  fi
  hr="$(retail "serviceName eq 'Virtual Machines' and armRegionName eq '$loc' and armSkuName eq '$size'" "$LINUX_ONDEMAND")"
  line "vm $name ($size)" "\$$hr/h" "${hr:+$(calc "$hr*$HOURS")}"
done < <(az vm list -d --subscription "$S" --query '[].[name, hardwareProfile.vmSize, location, powerState]' -o tsv 2>/dev/null)

# AKS nodes: scale sets in the MC_ resource groups (control plane is Free tier)
while IFS=$'\t' read -r name size loc count; do
  [[ -z "$name" ]] && continue
  hr="$(retail "serviceName eq 'Virtual Machines' and armRegionName eq '$loc' and armSkuName eq '$size'" "$LINUX_ONDEMAND")"
  line "aks nodes $name ($size)" "${count} x \$$hr/h" "${hr:+$(calc "$hr*$count*$HOURS")}"
done < <(az vmss list --subscription "$S" --query '[].[name, sku.name, location, sku.capacity]' -o tsv 2>/dev/null)

# Managed disks (VM and AKS node OS disks), by tier: E4 = Standard SSD 32 GiB, P4 = Premium 32 GiB
while IFS=$'\t' read -r name sku gb loc; do
  [[ -z "$name" ]] && continue
  case "$sku" in
    StandardSSD_LRS) family="Standard SSD Managed Disks" prefix=E ;;
    Premium_LRS) family="Premium SSD Managed Disks" prefix=P ;;
    *) line "disk $name" "$sku" ""; continue ;;
  esac
  tier=4; for t in 4:32 6:64 10:128 15:256 20:512; do [[ "$gb" -le "${t#*:}" ]] && { tier="${t%%:*}"; break; }; done
  mo="$(retail "serviceName eq 'Storage' and armRegionName eq '$loc' and skuName eq '$prefix$tier LRS' and productName eq '$family'" '| select(.unitOfMeasure=="1/Month" and (.meterName|test("Disk$")))')"
  line "disk $name" "$prefix$tier ${gb}GB" "$mo"
done < <(for rg in $(az group list --subscription "$S" --query '[].name' -o tsv 2>/dev/null); do
  az disk list -g "$rg" --subscription "$S" --query '[].[name, sku.name, diskSizeGB, location]' -o tsv 2>/dev/null
done) # az disk list needs -g in az 2.91

# Networking: fixed hourly charges (data processed is extra, cents here)
n="$(az network public-ip list --subscription "$S" --query "length([?sku.name=='Standard'])" -o tsv 2>/dev/null)"
hr="$(retail "serviceName eq 'Virtual Network' and armRegionName eq 'westus' and meterName eq 'Standard IPv4 Static Public IP'")"
[[ "${n:-0}" -gt 0 ]] && line "public IPs (Standard, static)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
n="$(az network nat gateway list --subscription "$S" --query 'length(@)' -o tsv 2>/dev/null)"
hr="$(retail "serviceName eq 'NAT Gateway' and meterName eq 'Standard Gateway'")"
[[ "${n:-0}" -gt 0 ]] && line "NAT gateways" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
n="$(az network lb list --subscription "$S" --query "length([?sku.name=='Standard'])" -o tsv 2>/dev/null)"
hr="$(retail "serviceName eq 'Load Balancer' and meterName eq 'Standard Included LB Rules and Outbound Rules'")"
[[ "${n:-0}" -gt 0 ]] && line "load balancers (Standard, first 5 rules)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
n="$(az network private-endpoint list --subscription "$S" --query 'length(@)' -o tsv 2>/dev/null)"
[[ "${n:-0}" -gt 0 ]] && line "private endpoints" "$n x \$$PRIVATE_ENDPOINT_HOUR/h" "$(calc "$PRIVATE_ENDPOINT_HOUR*$n*$HOURS")"

# Managed Redis (redisEnterprise), Service Bus Standard base charge
while IFS=$'\t' read -r name sku loc; do
  [[ -z "$name" ]] && continue
  size="${sku#*_}" # Balanced_B0 -> B0
  hr="$(retail "serviceName eq 'Redis Cache' and armRegionName eq '$loc' and meterName eq '$size Cache Instance'" "| select(.productName|test(\"${sku%%_*}\"))")"
  line "managed redis $name ($sku)" "\$$hr/h" "${hr:+$(calc "$hr*$HOURS")}"
done < <(az resource list --subscription "$S" --resource-type Microsoft.Cache/redisEnterprise --query '[].[name, sku.name, location]' -o tsv 2>/dev/null)
while IFS=$'\t' read -r name sku loc; do
  [[ -z "$name" ]] && continue
  mo="$(retail "serviceName eq 'Service Bus' and armRegionName eq '$loc' and meterName eq '$sku Base Unit'")"
  line "service bus $name ($sku)" "base" "$mo"
done < <(az servicebus namespace list --subscription "$S" --query '[].[name, sku.name, location]' -o tsv 2>/dev/null)

n="$(az resource list --subscription "$S" --resource-type Microsoft.App/containerApps --query 'length(@)' -o tsv 2>/dev/null)"
[[ "${n:-0}" -gt 0 ]] && printf "  %-46s %10s   \$%7.2f/mo\n" "container apps (scale to zero, free grant)" "$n" 0

topics="$(az eventgrid system-topic list --subscription "$S" --query 'length(@)' -o tsv 2>/dev/null)"
printf "  %-46s %10s         \$%7.4f/mo\n" "Event Grid system topics (free tier)" "${topics:-0}" 0
printf "\n  Estimated total: \$%.2f/month, \$%.2f/day (plus usage charges: data processed, operations, logs)\n" "$TOTAL" "$(calc "$TOTAL/30.4")"

echo
echo "== bluedragon-sre: billed cost by service, last $DAYS days (Cost Management) =="
END="$(date +%Y-%m-%d)"
START="$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)"
# Cost Management throttles repeated queries (HTTP 429 "Too many requests");
# wait and retry rather than report it as missing data.
cost_query() {
  az rest --method post \
  --uri "https://management.azure.com/subscriptions/$S/providers/Microsoft.CostManagement/query?api-version=2023-11-01" \
  --body "{\"type\":\"ActualCost\",\"timeframe\":\"Custom\",\"timePeriod\":{\"from\":\"$START\",\"to\":\"$END\"},
           \"dataset\":{\"granularity\":\"None\",\"aggregation\":{\"totalCost\":{\"name\":\"PreTaxCost\",\"function\":\"Sum\"}},
           \"grouping\":[{\"type\":\"Dimension\",\"name\":\"ServiceName\"}]}}" \
  -o json 2>&1 | grep -v -E 'SyntaxWarning|excludedActions'
}
for wait in 20 40 0; do
  COST_JSON="$(cost_query)"
  [[ "$COST_JSON" == *"Too many requests"* && "$wait" -gt 0 ]] || break
  echo "  (Cost Management rate limit; retrying in ${wait}s)"
  sleep "$wait"
done
printf '%s' "$COST_JSON" | python3 -c '
import json, re, sys
raw = sys.stdin.read()
try:
    p = json.loads(raw)["properties"]
except Exception:
    msg = re.search(r"\"message\":\"([^\"]+)", raw)
    print("  Cost Management: " + (msg.group(1) if msg else raw.strip()[:200]))
    if "Too many requests" in raw:
        print("  (Still rate limited; re-run in a few minutes.)")
    else:
        print("  (A new subscription can take up to 48 hours before Cost Management reports it.)")
    sys.exit(0)
cols = [c["name"] for c in p["columns"]]
cost_i, svc_i, cur_i = cols.index("PreTaxCost"), cols.index("ServiceName"), cols.index("Currency")
rows = sorted(p["rows"], key=lambda r: -r[cost_i])
for r in rows:
    print("  %-46s $%9.4f" % (r[svc_i], r[cost_i]))
if not rows:
    print("  $0.00 so far (or not reported yet: Cost Management lags a day or two)")
total = sum(r[cost_i] for r in rows)
currency = rows[0][cur_i] if rows else "USD"
print("\n  Billed total: $%.4f %s" % (total, currency))
'
