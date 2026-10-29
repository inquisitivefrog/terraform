#!/usr/bin/env bash
# Run the orders k6 load (app/k6/orders.js) as a Job in the cluster, next to
# the app, and follow it to the end. Results stream into Prometheus as they
# happen (dashboard "Relational / Orders load"); k6's own summary prints at
# the end.
# Usage: private/datastore-clusters/relational/scripts/load_test.sh pg|mysql seed [orders] [dev]
#        private/datastore-clusters/relational/scripts/load_test.sh pg|mysql run [rate] [duration] [dev]
#   seed  add orders in bulk (default 300000; 10000 customers the first
#         time), so the planted unindexed search is slow from the start
#   run   the CRUDS mix at a fixed rate (default 50 requests/s) for a fixed
#         time (default 5m). Exits non-zero if any SLO threshold failed or
#         an acknowledged write was lost.
# Rows written by a run are tagged with its id (run_id column, testid label).
# A run is runbook 5: logged in relational/logs/runbook-5-<engine>-<time>.txt
# (into the caller's log when a runbook script runs it).

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX

K6_IMAGE="grafana/k6:1.8.1" # 1.8.2 (2026-10-24) is days old
ENGINE="${1:-}"
MODE="${2:-}"
[[ "$ENGINE" =~ ^(pg|mysql)$ && "$MODE" =~ ^(seed|run)$ ]] || {
  echo "Usage: $0 pg|mysql seed [orders] [dev]  |  $0 pg|mysql run [rate] [duration] [dev]" >&2
  exit 1
}
if [[ "$MODE" == seed ]]; then
  SEED_ORDERS="${3:-300000}" RATE="" DURATION="" ENV="${4:-dev}"
else
  SEED_ORDERS="" RATE="${3:-50}" DURATION="${4:-5m}" ENV="${5:-dev}"
fi
# A bare number reaches k6 as milliseconds ("2" is 2ms), which it rejects
# only after the Job has started
[[ -z "$RATE" || "$RATE" =~ ^[1-9][0-9]*$ ]] || { echo "rate must be a whole number of requests/s, not '$RATE'" >&2; exit 1; }
[[ -z "$DURATION" || "$DURATION" =~ ^([0-9]+[hms])+$ ]] || { echo "duration needs a unit, e.g. 90s, 2m or 1h30m, not '$DURATION'" >&2; exit 1; }
[[ -z "$SEED_ORDERS" || "$SEED_ORDERS" =~ ^[1-9][0-9]*$ ]] || { echo "orders must be a whole number, not '$SEED_ORDERS'" >&2; exit 1; }
NS="relational"
use_cluster "datastore-$ENV"
[[ "$MODE" == run ]] && runbook_log "$(dirname "$0")/../logs" "runbook-5-$ENGINE" "$@"

[[ "$ENGINE" == pg ]] && LABEL="postgresql" || LABEL="mysql"
APP="orders-$ENGINE"
RUN_ID="$ENGINE-$MODE-$(date -u +%Y%m%d-%H%M%S)"
JOB="k6-$RUN_ID"

k -n "$NS" get configmap orders-k6 >/dev/null 2>&1 || {
  echo "No ConfigMap orders-k6: apply relational/environments/dev/app first." >&2
  exit 1
}
[[ "$(k -n "$NS" get deploy "$APP" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" -ge 1 ]] || {
  echo "Deployment $APP has no ready pods." >&2
  exit 1
}

k -n "$NS" apply -f - >/dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $JOB
  labels: {app.kubernetes.io/name: k6, app.kubernetes.io/instance: $APP}
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 86400
  template:
    metadata:
      labels: {app.kubernetes.io/name: k6, app.kubernetes.io/instance: $APP}
    spec:
      restartPolicy: Never
      securityContext: {runAsNonRoot: true, runAsUser: 12345, seccompProfile: {type: RuntimeDefault}}
      containers:
        - name: k6
          image: $K6_IMAGE
          args: [run, --quiet, -o, experimental-prometheus-rw, --tag, testid=$RUN_ID, --tag, engine=$LABEL, /scripts/orders.js]
          env:
            - {name: BASE_URL, value: "http://$APP.$NS.svc:8080"}
            - {name: MODE, value: "$MODE"}
            - {name: RATE, value: "$RATE"}
            - {name: DURATION, value: "$DURATION"}
            - {name: SEED_ORDERS, value: "$SEED_ORDERS"}
            - {name: RUN_ID, value: "$RUN_ID"}
            - {name: K6_PROMETHEUS_RW_SERVER_URL, value: "http://kube-prometheus-stack-prometheus.monitoring.svc:9090/api/v1/write"}
            - {name: K6_PROMETHEUS_RW_TREND_STATS, value: "p(95),p(99),avg,max"}
            - {name: K6_PROMETHEUS_RW_PUSH_INTERVAL, value: "5s"}
          resources:
            requests: {cpu: 200m, memory: 256Mi}
            limits: {memory: 512Mi}
          securityContext: {allowPrivilegeEscalation: false, readOnlyRootFilesystem: true, capabilities: {drop: [ALL]}}
          volumeMounts: [{name: scripts, mountPath: /scripts, readOnly: true}]
      volumes:
        - {name: scripts, configMap: {name: orders-k6}}
EOF

echo "Job $JOB: $MODE against $APP ${RATE:+at $RATE req/s for $DURATION}${SEED_ORDERS:+$SEED_ORDERS orders}"
echo "Grafana: http://localhost:3000/d/relational-orders-load?var-engine=$LABEL&var-testid=$RUN_ID (port-forward: platform/scripts/grafana_restart.sh)"
k -n "$NS" wait --for=condition=Ready pod -l "job-name=$JOB" --timeout=180s >/dev/null 2>&1 ||
  k -n "$NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod -l "job-name=$JOB" --timeout=5s >/dev/null 2>&1
k -n "$NS" logs -f "job/$JOB"

for _ in $(seq 1 30); do
  STATUS="$(k -n "$NS" get job "$JOB" -o jsonpath='{.status.succeeded}/{.status.failed}')"
  [[ "$STATUS" != "/" ]] && break
  sleep 2
done
echo
if [[ "$STATUS" == 1/* ]]; then
  echo "Run $RUN_ID: passed."
else
  echo "Run $RUN_ID: FAILED (a threshold was crossed, a write was lost, or k6 could not run)."
  exit 1
fi
