#!/usr/bin/env bash
# Confirm the shared private-cloud platform (the kind cluster every datastore
# category runs on) exists and is configured as intended.
# Usage: private/datastore-clusters/platform/scripts/check_resources.sh [dev]   (read-only; run from anywhere)

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX
source "$(dirname "$0")/../../../scripts/checks.sh"      # expect, match, summary
ENV="${1:-dev}"
ZONES="dc1-a dc1-b dc1-c"

scrape_targets() { echo "$(prom_count 'up==1') up, $(prom_count 'up==0') down"; }

# unlimited_containers <namespace>: running containers with no memory limit, or "all" (all have one)
unlimited_containers() {
  local out
  out="$(k -n "$1" get pods --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{range .spec.containers[*]}{.name}={.resources.limits.memory}{"\n"}{end}{end}' |
    grep '=$' | cut -d= -f1 | sort -u | xargs)"
  echo "${out:-all}"
}

use_cluster "datastore-$ENV"
echo "== private/datastore-clusters platform $ENV (kind cluster $CLUSTER, context $CTX) =="
echo
expect "Nodes Ready" "4" sh -c "kubectl --context $CTX get nodes --no-headers | grep -cw Ready"
expect "One worker per zone" "$ZONES" sh -c "kubectl --context $CTX get nodes -l '!node-role.kubernetes.io/control-plane' \
  -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io/zone}{\"\n\"}{end}' | sort | tr '\n' ' ' | sed 's/ \$//'"
expect "Every node in region dc1" "dc1" sh -c "kubectl --context $CTX get nodes \
  -o jsonpath='{range .items[*]}{.metadata.labels.topology\.kubernetes\.io/region}{\"\n\"}{end}' | sort -u"
expect "Control plane takes no workloads" "NoSchedule" k get nodes -l node-role.kubernetes.io/control-plane \
  -o jsonpath='{.items[0].spec.taints[?(@.key=="node-role.kubernetes.io/control-plane")].effect}'
match "API server only on localhost" '^https://127\.0\.0\.1:[0-9]+$' k config view --minify -o jsonpath='{.clusters[0].cluster.server}'
expect "Default StorageClass (one volume per node, like local disk)" "standard rancher.io/local-path WaitForFirstConsumer" k get storageclass \
  -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name} {.provisioner} {.volumeBindingMode}{end}'

# Shared monitoring (environments/dev/services): skipped if not applied yet.
echo
if ! k get namespace monitoring >/dev/null 2>&1; then
  echo "-- monitoring: namespace monitoring not found (services not applied); skipped --"
else
  echo "-- monitoring (kube-prometheus-stack) --"
  expect "Prometheus ready" "1" k -n monitoring get statefulset prometheus-kube-prometheus-stack-prometheus -o jsonpath='{.status.readyReplicas}'
  expect "Alertmanager ready" "1" k -n monitoring get statefulset alertmanager-kube-prometheus-stack-alertmanager -o jsonpath='{.status.readyReplicas}'
  expect "Grafana available" "1" k -n monitoring get deployment kube-prometheus-stack-grafana -o jsonpath='{.status.availableReplicas}'
  expect "Remote-write receiver on (k6 results)" "true" k -n monitoring get prometheus kube-prometheus-stack-prometheus -o jsonpath='{.spec.enableRemoteWriteReceiver}'
  match "Scrape targets" '^[1-9][0-9]* up, 0 down$' scrape_targets
  match "Dashboards loaded by Grafana's sidecar" '^[1-9][0-9]*$' sh -c "kubectl --context $CTX get configmap -A -l grafana_dashboard=1 --no-headers | wc -l | tr -d ' '"
  # Every alert but Watchdog goes to alert-log, which prints each notification
  # (kubectl -n monitoring logs deploy/alert-log); the chart's default is "null".
  expect "Alertmanager sends alerts to alert-log" "alert-log" sh -c \
    "kubectl --context $CTX get --raw /api/v1/namespaces/monitoring/services/kube-prometheus-stack-alertmanager:9093/proxy/api/v2/status | jq -r .config.original | sed -n 's/^  receiver: //p' | tr -d '\"'"
  expect "alert-log receiver available" "1" k -n monitoring get deployment alert-log -o jsonpath='{.status.availableReplicas}'
  # A container without a memory limit is unbounded on a node it shares with a database.
  expect "Every monitoring container has a memory limit" "all" unlimited_containers monitoring
fi

# cert-manager (environments/dev/services): certificates for the Barman Cloud
# plugin (docs/BACKUPS.md). Skipped if not applied yet.
echo
if ! k get namespace cert-manager >/dev/null 2>&1; then
  echo "-- cert-manager: namespace cert-manager not found (services not applied); skipped --"
else
  echo "-- cert-manager --"
  expect "Controller, webhook, cainjector available" "1 1 1" k -n cert-manager get deploy cert-manager cert-manager-webhook cert-manager-cainjector \
    -o jsonpath='{.items[*].status.availableReplicas}'
  expect "Every cert-manager container has a memory limit" "all" unlimited_containers cert-manager
fi

# The backup store (environments/dev/backup-store), outside the cluster:
# skipped if not applied yet.
STORE=datastore-backups
STORE_DIR="$HOME/.config/datastore-dev/backup-store"
STORE_KEYS="$STORE_DIR/s3.json"
STORE_CA="$STORE_DIR/ca.crt"
# s3_status <identity|anonymous> <bucket> [query]: HTTP status of a GET on
# the bucket (default: a listing) with that identity's key from STORE_KEYS,
# or none, over https checked against the store's CA. The key goes to curl
# as a config file on stdin: never on a command line, never printed.
s3_status() {
  local url="https://localhost:${STORE_PORT:-8333}/$2?${3:-list-type=2}"
  if [[ "$1" == anonymous ]]; then
    curl -s -o /dev/null -w '%{http_code}' --cacert "$STORE_CA" "$url"
    return
  fi
  python3 -c '
import json, sys
c = next(i for i in json.load(open(sys.argv[1]))["identities"] if i["name"] == sys.argv[2])["credentials"][0]
print("user = \"" + c["accessKey"] + ":" + c["secretKey"] + "\"")' "$STORE_KEYS" "$1" |
    curl -s -o /dev/null -w '%{http_code}' --cacert "$STORE_CA" --aws-sigv4 "aws:amz:us-east-1:s3" -K - "$url"
}
# bucket_encryption <bucket>: its default encryption, read with the admin key
bucket_encryption() {
  python3 -c '
import json, sys
c = next(i for i in json.load(open(sys.argv[1]))["identities"] if i["name"] == "admin")["credentials"][0]
print("user = \"" + c["accessKey"] + ":" + c["secretKey"] + "\"")' "$STORE_KEYS" |
    curl -s --cacert "$STORE_CA" --aws-sigv4 "aws:amz:us-east-1:s3" -K - "https://localhost:${STORE_PORT:-8333}/$1?encryption" |
    sed -n 's:.*<SSEAlgorithm>\([^<]*\)</SSEAlgorithm>.*:\1:p' | grep . || echo none
}
# cert_days: whole days the store's certificate has left, from the store itself
cert_days() {
  local end
  end="$(openssl s_client -connect "localhost:${STORE_PORT:-8333}" -servername localhost </dev/null 2>/dev/null |
    openssl x509 -noout -enddate | cut -d= -f2)"
  echo $((($(date -j -f '%b %e %T %Y %Z' "$end" +%s) - $(date +%s)) / 86400))
}
echo
if ! docker inspect "$STORE" >/dev/null 2>&1; then
  echo "-- backup store: container $STORE not found (backup-store not applied); skipped --"
else
  echo "-- backup store (SeaweedFS, outside the cluster) --"
  expect "Running" "true" docker inspect -f '{{.State.Running}}' "$STORE"
  # Terraform starts it by image ID, so the name is the image's tag
  match "Image is SeaweedFS" '(^| )chrislusf/seaweedfs:[0-9.]+( |$)' sh -c \
    "docker image inspect -f '{{range .RepoTags}}{{.}} {{end}}' \"\$(docker inspect -f '{{.Image}}' $STORE)\""
  expect "S3 published on localhost only" "127.0.0.1:8333" docker port "$STORE" 8333
  expect "Data on its own volume (outlives the container)" "volume ${STORE}-data" docker inspect \
    -f '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Name}}{{end}}{{end}}' "$STORE"
  expect "Keys mounted read-only" "bind false" docker inspect \
    -f '{{range .Mounts}}{{if eq .Destination "/etc/seaweedfs"}}{{.Type}} {{.RW}}{{end}}{{end}}' "$STORE"
  expect "Keys file readable by you only" "600" stat -f '%Lp' "$STORE_KEYS"
  # TLS (platform/scripts/backup_store_tls.sh)
  expect "Plain http refused (TLS only)" "400" curl -s -o /dev/null -w '%{http_code}' "http://localhost:${STORE_PORT:-8333}/"
  expect "Certificate checks against our CA" "403" s3_status anonymous pg-backups
  match "Certificate valid 30 days or more" '^([3-9][0-9]|[1-9][0-9]{2,})$' cert_days
  # Encryption at rest (backup_store_buckets.sh; the key from security.toml)
  expect "Encryption key file readable by you only" "600" stat -f '%Lp' "$STORE_DIR/security.toml"
  # Without it the store falls back, silently, to a key of its own on the
  # data volume (/data/.mini_sse_kek; tested 2026-11-04)
  expect "Encryption key seen by the store (security.toml, not the data volume)" "kek" sh -c \
    "docker exec $STORE sed -n 's/^kek *=.*/kek/p' /etc/seaweedfs/security.toml"
  for b in pg-backups mysql-backups; do
    expect "$b encrypted by default" "AES256" bucket_encryption "$b"
  done
  expect "No usage reports to telemetry.seaweedfs.com" "-master.telemetry=false" sh -c \
    "docker inspect -f '{{range .Args}}{{println .}}{{end}}' $STORE | grep -x -- -master.telemetry=false"
  for e in pg mysql; do
    other=mysql
    [[ "$e" == mysql ]] && other=pg
    expect "$e key lists $e-backups" "200" s3_status "$e" "$e-backups"
    expect "$e key refused on $other-backups" "403" s3_status "$e" "$other-backups"
  done
  expect "Anonymous access refused" "403" s3_status anonymous pg-backups
fi
summary "platform resources"
