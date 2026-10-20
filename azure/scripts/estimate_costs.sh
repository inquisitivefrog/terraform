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

topics="$(az eventgrid system-topic list --subscription "$S" --query 'length(@)' -o tsv 2>/dev/null)"
printf "  %-46s %10s         \$%7.4f/mo\n" "Event Grid system topics (free tier)" "${topics:-0}" 0
printf "\n  Estimated total: \$%.2f/month (plus per-operation charges, cents)\n" "$TOTAL"

echo
echo "== bluedragon-sre: billed cost by service, last $DAYS days (Cost Management) =="
END="$(date +%Y-%m-%d)"
START="$(date -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -d "-${DAYS} days" +%Y-%m-%d)"
az rest --method post \
  --uri "https://management.azure.com/subscriptions/$S/providers/Microsoft.CostManagement/query?api-version=2023-11-01" \
  --body "{\"type\":\"ActualCost\",\"timeframe\":\"Custom\",\"timePeriod\":{\"from\":\"$START\",\"to\":\"$END\"},
           \"dataset\":{\"granularity\":\"None\",\"aggregation\":{\"totalCost\":{\"name\":\"PreTaxCost\",\"function\":\"Sum\"}},
           \"grouping\":[{\"type\":\"Dimension\",\"name\":\"ServiceName\"}]}}" \
  -o json 2>&1 | grep -v -E 'SyntaxWarning|excludedActions' | python3 -c '
import json, re, sys
raw = sys.stdin.read()
try:
    p = json.loads(raw)["properties"]
except Exception:
    msg = re.search(r"\"message\":\"([^\"]+)", raw)
    print("  Cost Management: " + (msg.group(1) if msg else raw.strip()[:200]))
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
