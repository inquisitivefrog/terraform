#!/usr/bin/env bash
# What aws/ costs in this repo's account, two ways:
#   1. Estimate: live inventory in us-west-2 (dev) and us-west-1 (prod) x
#      on-demand list prices from the AWS Price List API (free to call).
#   2. Billed: month-to-date cost by service from Cost Explorer (lags about
#      a day; each call costs $0.01).
# AWS counterpart of azure/scripts/estimate_costs.sh.
# Usage: aws/scripts/estimate_costs.sh      (read-only)

set -uo pipefail

ACCOUNT_ID="084375569056" # this repo's account; never grid-meter's
REGIONS=(us-west-2 us-west-1)
HOURS=730
# Not worth an API lookup (USD, sourced 2026-10-21):
IPV4_HOUR=0.005    # every public IPv4 address, attached or not
KMS_KEY_MONTH=1.00 # each enabled customer managed key
FARGATE_VCPU_HOUR=0.04048
FARGATE_GB_HOUR=0.004445

account="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
if [[ "$account" != "$ACCOUNT_ID" ]]; then
  echo "Logged in to account '${account:-none}', expected $ACCOUNT_ID. Stopping." >&2
  exit 1
fi

calc() { awk "BEGIN{printf \"%.4f\", $1}"; }
TOTAL=0
declare -A CACHE=()

# price <service> <description regex> <filters...>: first matching on-demand USD price
price() {
  local svc="$1" want="$2" key
  shift 2
  key="$svc|$want|$*"
  if [[ -z "${CACHE[$key]+x}" ]]; then
    CACHE[$key]="$(aws pricing get-products --region us-east-1 --service-code "$svc" --filters "$@" --output json 2>/dev/null |
      jq -r --arg w "$want" '[.PriceList[]? | fromjson | .terms.OnDemand[]?.priceDimensions[]?
        | select(.description | test($w)) | .pricePerUnit.USD | tonumber] | .[0] // empty')"
  fi
  printf '%s' "${CACHE[$key]}"
}
f() { printf 'Type=TERM_MATCH,Field=%s,Value=%s' "$1" "$2"; }

# line <label> <detail> <monthly or empty>
line() {
  if [[ -z "$3" ]]; then
    printf "  %-48s %16s   (price not found)\n" "$1" "$2"
    return
  fi
  printf "  %-48s %16s   \$%8.2f/mo\n" "$1" "$2" "$3"
  TOTAL="$(calc "$TOTAL+$3")"
}

echo "== account $ACCOUNT_ID: estimate from live resources (on-demand list price) =="
for r in "${REGIONS[@]}"; do
  echo "  -- $r"
  # EC2, including EKS worker nodes
  while read -r type n; do
    [[ -z "$type" ]] && continue
    hr="$(price AmazonEC2 'On Demand Linux' "$(f instanceType "$type")" "$(f regionCode "$r")" "$(f operatingSystem Linux)" \
      "$(f tenancy Shared)" "$(f preInstalledSw NA)" "$(f capacitystatus Used)")"
    line "ec2 $type (incl. EKS nodes)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
  done < <(aws ec2 describe-instances --region "$r" --filters Name=instance-state-name,Values=running \
    --query 'Reservations[].Instances[].InstanceType' --output text 2>/dev/null | tr '\t' '\n' | sort | uniq -c | awk '{print $2, $1}')

  # EBS volumes by type
  while read -r vtype gb; do
    [[ -z "$vtype" ]] && continue
    mo="$(price AmazonEC2 'GB-month|GB-Mo' "$(f volumeApiName "$vtype")" "$(f regionCode "$r")" "$(f productFamily Storage)")"
    line "ebs $vtype" "${gb} GB" "${mo:+$(calc "$mo*$gb")}"
  done < <(aws ec2 describe-volumes --region "$r" --query 'Volumes[].[VolumeType,Size]' --output text 2>/dev/null |
    awk '{s[$1]+=$2} END {for (t in s) print t, s[t]}')

  n="$(aws eks list-clusters --region "$r" --query 'length(clusters)' --output text 2>/dev/null)"
  if [[ "${n:-0}" -gt 0 ]]; then
    hr="$(price AmazonEKS 'cluster usage' "$(f regionCode "$r")" "$(f operation CreateOperation)")"
    line "eks control plane" "$n x \$${hr:-0.10}/h" "$(calc "${hr:-0.10}*$n*$HOURS")"
  fi

  n="$(aws ec2 describe-nat-gateways --region "$r" --filter Name=state,Values=available --query 'length(NatGateways)' --output text 2>/dev/null)"
  if [[ "${n:-0}" -gt 0 ]]; then
    hr="$(price AmazonEC2 'per NAT Gateway Hour' "$(f regionCode "$r")" "$(f productFamily 'NAT Gateway')")"
    line "nat gateways (+ data processed)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
  fi

  eips="$(aws ec2 describe-addresses --region "$r" --query 'length(Addresses)' --output text 2>/dev/null)"
  pubs="$(aws ec2 describe-instances --region "$r" --filters Name=instance-state-name,Values=running \
    --query 'length(Reservations[].Instances[?PublicIpAddress && !(contains(PublicIpAddress, `x`))][])' --output text 2>/dev/null)"
  n=$((${eips:-0} + ${pubs:-0}))
  [[ "$n" -gt 0 ]] && line "public IPv4 addresses (EIPs + instance IPs)" "$n x \$$IPV4_HOUR/h" "$(calc "$IPV4_HOUR*$n*$HOURS")"

  while read -r ntype engine n; do
    [[ -z "$ntype" ]] && continue
    hr="$(price AmazonElastiCache 'node-hour' "$(f instanceType "$ntype")" "$(f regionCode "$r")" "$(f cacheEngine "${engine^}")")"
    line "elasticache $ntype ($engine)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
  done < <(aws elasticache describe-cache-clusters --region "$r" --query 'CacheClusters[].[CacheNodeType,Engine,NumCacheNodes]' \
    --output text 2>/dev/null | awk '{k=$1" "$2; s[k]+=$3} END {for (x in s) print x, s[x]}')

  n="$(aws elbv2 describe-load-balancers --region "$r" --query "length(LoadBalancers[?Type=='application'])" --output text 2>/dev/null)"
  if [[ "${n:-0}" -gt 0 ]]; then
    hr="$(price AWSELB 'LoadBalancer-hour|per Application LoadBalancer-hour' "$(f regionCode "$r")" "$(f productFamily 'Load Balancer-Application')")"
    line "application load balancers (+ LCUs)" "$n x \$$hr/h" "${hr:+$(calc "$hr*$n*$HOURS")}"
  fi

  # ECS Fargate: running tasks x their CPU and memory
  for cl in $(aws ecs list-clusters --region "$r" --query 'clusterArns' --output text 2>/dev/null); do
    tasks="$(aws ecs list-tasks --region "$r" --cluster "$cl" --desired-status RUNNING --query taskArns --output text 2>/dev/null)"
    [[ -z "$tasks" || "$tasks" == "None" ]] && continue
    read -r cpu mem < <(aws ecs describe-tasks --region "$r" --cluster "$cl" --tasks $tasks \
      --query 'tasks[].[cpu,memory]' --output text 2>/dev/null | awk '{c+=$1; m+=$2} END {print c/1024, m/1024}')
    line "ecs fargate ${cl##*/}" "${cpu} vCPU ${mem} GB" "$(calc "($cpu*$FARGATE_VCPU_HOUR+$mem*$FARGATE_GB_HOUR)*$HOURS")"
  done

  n=0
  for k in $(aws kms list-keys --region "$r" --query 'Keys[].KeyId' --output text 2>/dev/null); do
    [[ "$(aws kms describe-key --region "$r" --key-id "$k" \
      --query 'join(`/`, [KeyMetadata.KeyManager, KeyMetadata.KeyState])' --output text 2>/dev/null)" == "CUSTOMER/Enabled" ]] && n=$((n + 1))
  done
  [[ "$n" -gt 0 ]] && line "kms customer managed keys (enabled)" "$n x \$$KMS_KEY_MONTH" "$(calc "$KMS_KEY_MONTH*$n")"
done

n="$(aws s3api list-buckets --query "length(Buckets[?starts_with(Name, 'bluedragon-')])" --output text 2>/dev/null)"
printf "  %-48s %16s   %s\n" "s3 bluedragon-* buckets (cents unless large)" "${n:-0}" "not priced"
printf "\n  Estimated total: \$%.2f/month, \$%.2f/day (plus usage: data processed, requests, logs)\n" "$TOTAL" "$(calc "$TOTAL/30.4")"

echo
echo "== account $ACCOUNT_ID: billed month to date by service (Cost Explorer, \$0.01 per call) =="
start="$(date +%Y-%m-01)"
end="$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d tomorrow +%Y-%m-%d)"
aws ce get-cost-and-usage --time-period "Start=$start,End=$end" --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE --output json 2>/dev/null |
  jq -r '.ResultsByTime[0].Groups[]? | "\(.Keys[0])\t\(.Metrics.UnblendedCost.Amount)"' |
  sort -t$'\t' -k2 -rn |
  awk -F'\t' '{t+=$2; if ($2 >= 0.005) printf "  %-46s $%8.2f\n", substr($1,1,46), $2} END {printf "\n  Billed total: $%.2f USD\n", t}'
