#!/usr/bin/env bash
# Confirm every gcp/single_instance resource exists and is healthy, by asking
# the GCP APIs directly rather than trusting "Apply complete".
# Usage: ./check_resources.sh dev|prod      (run from anywhere; read-only)
# Adapted from grid-meter-app's check-resources-gcp.sh, including its two
# false-PASS guards (see tf_output and check below).

set -uo pipefail

env=${1:-}
case "$env" in
  dev | prod) ;;
  *)
    echo "Usage: $0 dev|prod" >&2
    exit 1
    ;;
esac

TF_DIR="$(cd "$(dirname "$0")/../single_instance/environments/$env" && pwd)"

# terraform output -raw prints its "No outputs found" warning to stdout and
# exits 0 on empty state; a real value is one line, so reject multi-line ones.
tf_output() {
  local val
  val="$(cd "$TF_DIR" && terraform output -raw "$1" 2>/dev/null)"
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}

P="$(tf_output project_id)"
ZONE="$(tf_output zone)"
CLUSTER="$(tf_output gke_cluster_name)"
if [[ -z "$P" || -z "$ZONE" || -z "$CLUSTER" ]]; then
  echo "No terraform outputs for $env: has 'terraform apply' been run?"
  exit 2
fi
REGION="${ZONE%-*}"
SUFFIX="${CLUSTER##*-}" # gke-<env>-<suffix>; shared by key ring and buckets

PASS=0
FAIL=0

# check <label> <command...>: PASS needs exit 0 AND non-empty stdout. gcloud
# list commands exit 0 with empty stdout when nothing matches, so the exit
# code alone would pass a missing resource.
check() {
  local label="$1" out rc errfile
  shift
  errfile="$(mktemp)"
  out="$("$@" 2>"$errfile")"
  rc=$?
  if [[ $rc -eq 0 && -n "$out" && "$out" != "None" ]]; then
    echo "  PASS  $label: ${out//$'\n'/, }"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: ${out:-not found} $(head -c 200 "$errfile")"
    FAIL=$((FAIL + 1))
  fi
  rm -f "$errfile"
}

# expect <label> <wanted> <command...>: PASS only if stdout equals <wanted>.
expect() {
  local label="$1" want="$2" out
  shift 2
  out="$("$@" 2>/dev/null)"
  if [[ "$out" == "$want" ]]; then
    echo "  PASS  $label: $out"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: expected '$want', got '${out:-nothing}'"
    FAIL=$((FAIL + 1))
  fi
}

# count <label> <min> <max> <command...>: PASS if the number of output lines is in range.
count() {
  local label="$1" min="$2" max="$3" n
  shift 3
  n="$("$@" 2>/dev/null | grep -c . || true)"
  if [[ "$n" -ge "$min" && "$n" -le "$max" ]]; then
    echo "  PASS  $label: $n"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  $label: got $n, expected $min-$max"
    FAIL=$((FAIL + 1))
  fi
}

echo "== gcp/single_instance $env (project $P, zone $ZONE, suffix $SUFFIX) =="

echo
echo "-- State --"
check "State object" gcloud storage ls "gs://bluedragon-tfstate-admin-$env/single_instance/default.tfstate" --project "$P"

echo
echo "-- Networking --"
check "VPC" gcloud compute networks describe "vpc-main-$env" --project "$P" --format="value(name)"
check "Public subnet" gcloud compute networks subnets describe "public-$env" --region "$REGION" --project "$P" --format="value(ipCidrRange)"
check "Private subnet" gcloud compute networks subnets describe "private-$env" --region "$REGION" --project "$P" --format="value(ipCidrRange)"
expect "Flow logs on private subnet" "True" gcloud compute networks subnets describe "private-$env" --region "$REGION" --project "$P" --format="value(logConfig.enable)"
check "Cloud NAT" gcloud compute routers nats describe "nat-$env" --router "router-$env" --region "$REGION" --project "$P" --format="value(name)"
count "Firewall rules (ours, excl. GKE's)" 11 11 gcloud compute firewall-rules list --project "$P" --filter="network~vpc-main-$env\$ AND name~-$env\$" --format="value(name)"

echo
echo "-- Compute --"
expect "Public VM" "RUNNING" gcloud compute instances describe "public-vm-$env" --zone "$ZONE" --project "$P" --format="value(status)"
check "Public VM external IP" gcloud compute instances describe "public-vm-$env" --zone "$ZONE" --project "$P" --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
expect "Private VM" "RUNNING" gcloud compute instances describe "private-vm-$env" --zone "$ZONE" --project "$P" --format="value(status)"
expect "Private VM has no external IP" "" gcloud compute instances describe "private-vm-$env" --zone "$ZONE" --project "$P" --format="value(networkInterfaces[0].accessConfigs[0].natIP)"
expect "Cloud Run nginx ready" "True" gcloud run services describe "nginx-$env" --region "$REGION" --project "$P" --format="value(status.conditions[0].status)"
expect "Cloud Run ingress" "internal" gcloud run services describe "nginx-$env" --region "$REGION" --project "$P" --format="value(metadata.annotations.'run.googleapis.com/ingress')"

echo
echo "-- GKE --"
expect "Cluster" "RUNNING" gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$P" --format="value(status)"
check "Cluster version" gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$P" --format="value(currentMasterVersion)"
expect "Secrets encryption key" "gke-secrets-key" gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$P" --format="value(databaseEncryption.keyName.basename())"
expect "Private nodes" "True" gcloud container clusters describe "$CLUSTER" --zone "$ZONE" --project "$P" --format="value(privateClusterConfig.enablePrivateNodes)"
expect "Node pool" "RUNNING" gcloud container node-pools describe "np-$env-$SUFFIX" --cluster "$CLUSTER" --zone "$ZONE" --project "$P" --format="value(status)"
# Instance names are truncated at 63 chars; GKE's cluster label is not.
count "Nodes RUNNING (autoscaler 1-3)" 1 3 gcloud compute instances list --project "$P" --filter="labels.goog-k8s-cluster-name=$CLUSTER AND status=RUNNING" --format="value(name)"

echo
echo "-- Memorystore --"
expect "Redis" "READY" gcloud redis instances describe "redis-$env" --region "$REGION" --project "$P" --format="value(state)"
expect "Redis AUTH" "True" gcloud redis instances describe "redis-$env" --region "$REGION" --project "$P" --format="value(authEnabled)"
expect "Redis TLS" "SERVER_AUTHENTICATION" gcloud redis instances describe "redis-$env" --region "$REGION" --project "$P" --format="value(transitEncryptionMode)"

echo
echo "-- KMS (key ring single-instance-$env-$SUFFIX) --"
for key in gke-secrets-key messages-key symmetric-key asymmetric-key; do
  count "$key enabled versions" 1 99 gcloud kms keys versions list --key "$key" --keyring "single-instance-$env-$SUFFIX" --location "$REGION" --project "$P" --filter="state=ENABLED" --format="value(name)"
done

echo
echo "-- Pub/Sub and Storage --"
check "Topic example-topic-$env" gcloud pubsub topics describe "example-topic-$env" --project "$P" --format="value(kmsKeyName.basename())"
check "Topic custom-topic-$env" gcloud pubsub topics describe "custom-topic-$env" --project "$P" --format="value(kmsKeyName.basename())"
expect "Ordered subscription" "True" gcloud pubsub subscriptions describe "custom-ordered-$env" --project "$P" --format="value(enableMessageOrdering)"
check "Dev bucket (CMEK)" gcloud storage buckets describe "gs://bluedragon-dev-bucket-$SUFFIX" --project "$P" --format="value(default_kms_key.basename())"
check "Log bucket (CMEK)" gcloud storage buckets describe "gs://bluedragon-log-bucket-$SUFFIX" --project "$P" --format="value(default_kms_key.basename())"

echo
echo "-- Service accounts --"
for sa in vm gke-node cloudrun developer admin sre dba; do
  check "$sa-$env" gcloud iam service-accounts describe "$sa-$env@$P.iam.gserviceaccount.com" --project "$P" --format="value(email)"
done

if [[ "$env" == "dev" ]]; then
  echo
  echo "-- Kubernetes (dev only; kubeconfig ~/.kube/gcp-dev) --"
  export KUBECONFIG=~/.kube/gcp-dev # never ~/.kube/config
  gcloud container clusters get-credentials "$CLUSTER" --zone "$ZONE" --project "$P" >/dev/null 2>&1
  expect "heartbeat-app ready" "2" kubectl get deployment heartbeat-app -n app1 -o jsonpath='{.status.readyReplicas}'
  expect "monitor-app ready" "2" kubectl get deployment monitor-app -n app2 -o jsonpath='{.status.readyReplicas}'
  expect "Resource quotas" "2" bash -c "kubectl get resourcequota -A --no-headers | grep -c -E '^app[12] '"
  expect "sre can list pods in app1" "yes" kubectl auth can-i list pods -n app1 --as="sre-$env@$P.iam.gserviceaccount.com"
  expect "sre can't list pods in app2" "no" kubectl auth can-i list pods -n app2 --as="sre-$env@$P.iam.gserviceaccount.com"
  ingress_ip="$(kubectl get ingress app-ingress -n app1 -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
  check "Ingress IP" printf '%s' "$ingress_ip"
  [[ -n "$ingress_ip" ]] && expect "Ingress HTTP" "200" curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$ingress_ip/"
fi

echo
echo "== Summary: $PASS passed, $FAIL failed =="
if [[ "$FAIL" -gt 0 ]]; then
  echo "One or more expected resources are missing or unhealthy."
  exit 1
fi
echo "All expected resources present and healthy."
