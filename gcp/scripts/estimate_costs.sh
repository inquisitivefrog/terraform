#!/usr/bin/env bash
# Ballpark list-price cost of what gcp/single_instance has running right now:
# inventory live resources, multiply by published rates.
# Usage: ./estimate_costs.sh dev|prod|all      (run from anywhere; read-only)
# Adapted from grid-meter-app's estimate-costs-gcp.sh.
#
# NOT billing data. GCP has no Cost Explorer equivalent without a Console-only
# billing export to BigQuery. Excluded: usage-based charges (egress, Cloud NAT
# and load-balancer data processing, flow-log ingestion past Logging's free
# 50 GiB/month, Pub/Sub, Cloud Storage), Cloud Run (scales to zero), discounts
# and credits other than the GKE one below.
# Also left out: gcp/tfstate (4 buckets + 4 KMS keys, about $0.30/month).

set -uo pipefail

case "${1:-}" in
  dev | prod) envs=("$1") ;;
  all) envs=(dev prod) ;;
  *)
    echo "Usage: $0 dev|prod|all" >&2
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- List-price rate card, USD per hour unless noted (sourced 2026-10-20) ---
# us-west1 rates match us-central1. us-west2 (Los Angeles) compute and disk
# list about 20% higher; sources disagreed on exact figures, so a 1.2
# multiplier is applied to those lines there. Least certain numbers here.
E2_MEDIUM=0.0335 # GKE nodes
E2_MICRO=0.0084  # VMs. One us-west1 e2-micro per billing account is Always Free
PD_BALANCED_GB_MONTH=0.10
GKE_CLUSTER_FEE=0.10 # $74.40/month credit covers one zonal cluster per billing account
REDIS_BASIC_GB=0.049 # Memorystore Redis Basic M1, per GiB-hour, same in both regions
NAT_PER_VM=0.0014    # capped at 0.044 (32 VMs)
NAT_CAP=0.044
EXTERNAL_IP=0.005           # in-use IPv4: public VM, Cloud NAT
FORWARDING_RULE=0.025       # first 5 rules, global external HTTP LB (GKE ingress)
KMS_SOFTWARE_MONTH=0.06     # per symmetric key version per month
KMS_ASYMMETRIC_MONTH=0.15   # per RSA signing key version per month
HOURS_MONTH=730

tf_output() {
  local val
  val="$(cd "$SCRIPT_DIR/../single_instance/environments/$1" && terraform output -raw "$2" 2>/dev/null)"
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}

calc() { awk "BEGIN{printf \"%.4f\", $1}"; }

TOTAL=0
line() { # line <label> <hourly>
  printf "  %-56s \$%.4f/hr  \$%6.2f/day  \$%7.2f/mo\n" "$1" "$2" "$(calc "$2*24")" "$(calc "$2*$HOURS_MONTH")"
  TOTAL="$(calc "$TOTAL+$2")"
}

# GKE's free cluster-fee credit is per billing account. Count clusters in
# the account's other projects (dairyfarm/grid-meter; names only, read-only):
# if any exist, assume one of them takes the credit and price ours at list.
SRE_PROJECT="$(tf_output "${envs[0]}" project_id)"
billing="$(gcloud billing projects describe "$SRE_PROJECT" --format='value(billingAccountName.basename())' 2>/dev/null)"
OTHER_CLUSTERS=0
if [[ -n "$billing" ]]; then
  for proj in $(gcloud billing projects list --billing-account="$billing" --format='value(projectId)' 2>/dev/null); do
    [[ "$proj" == "$SRE_PROJECT" ]] && continue
    n="$(gcloud container clusters list --project "$proj" --format='value(name)' 2>/dev/null | grep -c . || true)"
    OTHER_CLUSTERS=$((OTHER_CLUSTERS + n))
  done
fi
FREE_CLUSTER_LEFT=$([[ "$OTHER_CLUSTERS" -eq 0 ]] && echo 1 || echo 0)

for env in "${envs[@]}"; do
  P="$(tf_output "$env" project_id)"
  ZONE="$(tf_output "$env" zone)"
  CLUSTER="$(tf_output "$env" gke_cluster_name)"
  echo
  if [[ -z "$P" || -z "$ZONE" ]]; then
    echo "== $env: no terraform outputs (not applied, or destroyed): \$0.00 =="
    continue
  fi
  REGION="${ZONE%-*}"
  mult=$([[ "$REGION" == "us-west2" ]] && echo 1.2 || echo 1.0)
  echo "== $env ($P, $ZONE; compute/disk rate x$mult) =="

  # Compute: VMs and GKE nodes, by live machine type
  vms="$(gcloud compute instances list --project "$P" --filter="zone~$ZONE\$ AND status=RUNNING AND name~-vm-$env\$" --format='value(name)' 2>/dev/null | grep -c . || true)"
  nodes=0
  if [[ -n "$CLUSTER" ]]; then
    nodes="$(gcloud compute instances list --project "$P" --filter="labels.goog-k8s-cluster-name=$CLUSTER AND status=RUNNING" --format='value(name)' 2>/dev/null | grep -c . || true)"
  fi
  [[ "$vms" -gt 0 ]] && line "$vms x e2-micro VM" "$(calc "$vms*$E2_MICRO*$mult")"
  [[ "$nodes" -gt 0 ]] && line "$nodes x e2-medium GKE node" "$(calc "$nodes*$E2_MEDIUM*$mult")"

  # Disks in this zone (VM and node boot disks)
  disk_gb="$(gcloud compute disks list --project "$P" --filter="zone~$ZONE\$" --format='value(sizeGb)' 2>/dev/null | awk '{s+=$1} END{print s+0}')"
  [[ "$disk_gb" -gt 0 ]] && line "${disk_gb} GB pd-balanced disks" "$(calc "$disk_gb*$PD_BALANCED_GB_MONTH*$mult/$HOURS_MONTH")"

  # GKE cluster fee
  if [[ -n "$CLUSTER" ]] && gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$P" --format='value(name)' >/dev/null 2>&1; then
    if [[ "$FREE_CLUSTER_LEFT" -eq 1 ]]; then
      line "GKE cluster fee (free-tier credit covers it)" 0
      FREE_CLUSTER_LEFT=0
    else
      line "GKE cluster fee (credit already used: list)" "$GKE_CLUSTER_FEE"
    fi
  fi

  # Memorystore
  redis_gb="$(gcloud redis instances describe "redis-$env" --region "$REGION" --project "$P" --format='value(memorySizeGb)' 2>/dev/null)"
  [[ -n "$redis_gb" ]] && line "Memorystore Redis Basic ${redis_gb} GB" "$(calc "$redis_gb*$REDIS_BASIC_GB")"

  # Cloud NAT gateway (private VM + nodes) and its IP
  if gcloud compute routers nats describe "nat-$env" --router "router-$env" --region "$REGION" --project "$P" --format='value(name)' >/dev/null 2>&1; then
    nat_vms=$((nodes + 1))
    line "Cloud NAT ($nat_vms VMs + 1 IP, excl. data)" "$(calc "(($nat_vms*$NAT_PER_VM<$NAT_CAP)?$nat_vms*$NAT_PER_VM:$NAT_CAP)+$EXTERNAL_IP")"
  fi

  # Public VM's external IP
  pub_ip="$(gcloud compute instances describe "public-vm-$env" --zone "$ZONE" --project "$P" --format='value(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)"
  [[ -n "$pub_ip" ]] && line "Public VM external IP" "$EXTERNAL_IP"

  # GKE ingress load balancer (dev only), named k8s2-fr-<id>-app1-app-ingress-<id>
  fr=0 # forwarding rules are project-wide; only dev has the Kubernetes layer
  [[ "$env" == "dev" ]] && fr="$(gcloud compute forwarding-rules list --project "$P" --global --filter="name~app1-app-ingress" --format='value(name)' 2>/dev/null | grep -c . || true)"
  [[ "$fr" -gt 0 ]] && line "Ingress load balancer ($fr forwarding rule, excl. data)" "$FORWARDING_RULE"

  # KMS: billed per enabled key version per month
  ring="single-instance-$env-${CLUSTER##*-}"
  sym=0
  asym=0
  for key in gke-secrets-key messages-key symmetric-key; do
    n="$(gcloud kms keys versions list --key "$key" --keyring "$ring" --location "$REGION" --project "$P" --filter='state=ENABLED' --format='value(name)' 2>/dev/null | grep -c . || true)"
    sym=$((sym + n))
  done
  asym="$(gcloud kms keys versions list --key asymmetric-key --keyring "$ring" --location "$REGION" --project "$P" --filter='state=ENABLED' --format='value(name)' 2>/dev/null | grep -c . || true)"
  [[ $((sym + asym)) -gt 0 ]] && line "KMS ($sym symmetric + $asym RSA key versions)" "$(calc "($sym*$KMS_SOFTWARE_MONTH+$asym*$KMS_ASYMMETRIC_MONTH)/$HOURS_MONTH")"
done

echo
printf "== Estimated total: \$%.4f/hr   \$%.2f/day   \$%.2f/mo ==\n" "$TOTAL" "$(calc "$TOTAL*24")" "$(calc "$TOTAL*$HOURS_MONTH")"
echo "   List prices; excludes usage-based charges (see header). GKE clusters on the"
echo "   billing account's other projects: $OTHER_CLUSTERS. The free cluster-fee credit covers"
echo "   one cluster on the account; with 'all', it's given to dev."
