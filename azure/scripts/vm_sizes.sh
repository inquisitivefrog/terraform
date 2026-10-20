#!/usr/bin/env bash
# Which small VM sizes can the bluedragon-sre subscription actually use?
# New pay-as-you-go subscriptions are often blocked from some sizes in busy
# regions ("NotAvailableForSubscription") and have per-family vCPU quotas.
# Usage: ./vm_sizes.sh [max-vcpus] [region ...]
#   ./vm_sizes.sh                      # <= 4 vCPUs in westus2 westus westus3
#   ./vm_sizes.sh 2 centralus eastus2  # <= 2 vCPUs in those regions
# Read-only. Prints usable sizes (no restriction, family quota > 0).

set -uo pipefail

S=8d75b8ef-999c-4f70-99a9-4eb0197f3a07 # bluedragon-sre, never the az default
MAX_VCPUS="${1:-4}"
shift || true
REGIONS=("${@:-}")
[[ -z "${REGIONS[0]}" ]] && REGIONS=(westus2 westus westus3)

for region in "${REGIONS[@]}"; do
  echo "== $region (sizes with <= $MAX_VCPUS vCPUs)"
  quotas="$(az vm list-usage --location "$region" --subscription "$S" \
    --query "[].{n:name.value,used:currentValue,limit:limit}" -o json 2>/dev/null)"
  az vm list-skus --location "$region" --subscription "$S" --resource-type virtualMachines \
    -o json 2>/dev/null | QUOTAS="$quotas" MAX="$MAX_VCPUS" python3 -c '
import json, os, sys
skus = json.load(sys.stdin)
quotas = {q["n"].lower(): q for q in json.loads(os.environ["QUOTAS"] or "[]")}
regional = quotas.get("cores", {})
print("   regional vCPU quota: %s used of %s" % (regional.get("used", "?"), regional.get("limit", "?")))
rows, blocked = [], 0
for s in skus:
    caps = {c["name"]: c["value"] for c in s.get("capabilities", [])}
    vcpus = int(caps.get("vCPUs", 0) or 0)
    if not vcpus or vcpus > int(os.environ["MAX"]):
        continue
    if s.get("restrictions"):
        blocked += 1
        continue
    q = quotas.get((s.get("family") or "").lower(), {})
    if int(q.get("limit") or 0) <= 0:   # limit comes back as a string
        continue
    rows.append((vcpus, float(caps.get("MemoryGB", 0)), s["name"], s["family"], q["used"], q["limit"]))
rows = sorted(set(rows))
for v, mem, name, fam, used, limit in rows:
    print("   %-22s %d vCPU %5.1f GB   %-28s quota %s/%s" % (name, v, mem, fam, used, limit))
if not rows:
    print("   (no usable sizes)")
print("   %d more sizes blocked for this subscription in this region" % blocked)
'
done
