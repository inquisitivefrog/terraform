#!/usr/bin/env bash
# Runbook 7, the alerts: prove "last good backup too old" fires on both
# engines, reaches the receiver, and resolves. Nothing is broken on purpose:
# the threshold is lowered instead (relational clusters root), so the
# newest real backups become "too old" within minutes:
#   terraform apply -var backup_alert_after_hours=0.1     (360 s)
#   runbook_7_alerts.sh fire       # waits until both fire, up to 30 min
#   terraform apply                                        (back to 192 h)
#   runbook_7_alerts.sh resolve    # waits until both resolve, up to 10 min
# Checks, per alert (PostgreSQLBackupTooOld, MySQLBackupTooOld):
#   fire     firing in Prometheus, held by Alertmanager, and a "firing" line
#            in alert-log (kubectl -n monitoring logs deploy/alert-log)
#   resolve  no longer firing, and a "resolved" line in alert-log
# Watches only; the applies are by hand.
# Usage: private/datastore-clusters/relational/scripts/runbook_7_alerts.sh fire|resolve [dev]
# Log: relational/logs/runbook-7-alerts-<mode>-<time>.txt (-FAILED.txt if it fails)

MODE="${1:-}"
[[ "$MODE" == fire || "$MODE" == resolve ]] || {
  echo "Usage: $0 fire|resolve [dev]" >&2
  exit 1
}
ENV="${2:-dev}"
ENGINE=mysql # for the library's engine switch; this runbook covers both
source "$(dirname "$0")/runbook_lib.sh" # pass, fail, summary
ALERTS=(PostgreSQLBackupTooOld MySQLBackupTooOld)
# Matched by the rules' own labels, cluster and namespace (max() keeps no
# other; 2026-11-04 the first rules had no namespace, and alert-log printed
# "-/pg")
declare -A CLUSTER_OF=([PostgreSQLBackupTooOld]=pg [MySQLBackupTooOld]=mysql)
NOTIFY_WAIT=420 # Alertmanager: group_wait 30 s, then group_interval 5 m for a change in the group

use_cluster "datastore-$ENV"
runbook_log "$LIB_DIR/../logs" "runbook-7-alerts-$MODE" "$@"
echo "== Runbook 7: backup alerts, $MODE ($(date -u +%Y-%m-%dT%H:%M:%SZ)) =="
# alert-log lines from the last hour: the notification may come before this
# run starts (fire rerun; resolve after a late apply)
START="$(date -u -v-60M +%Y-%m-%dT%H:%M:%SZ)"

prom_api() { k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-prometheus:http-web/proxy/api/v1/$1"; }
prom_q() { prom_api "query?query=$(printf %s "$1" | jq -sRr @uri)"; }
alert_state() {
  prom_q "ALERTS{alertname=\"$1\",cluster=\"${CLUSTER_OF[$1]}\",namespace=\"$NS\"}" |
    jq -r '[.data.result[].metric.alertstate] | if any(. == "firing") then "firing" elif any(. == "pending") then "pending" else "" end'
}
in_alertmanager() {
  k get --raw "/api/v1/namespaces/monitoring/services/kube-prometheus-stack-alertmanager:http-web/proxy/api/v2/alerts?active=true&filter=$(printf %s "alertname=\"$1\"" | jq -sRr @uri)" | jq length
}
# logged <status> <alertname>: alert-log printed that since this run started
logged() { k -n monitoring logs deploy/alert-log --since-time="$START" 2>/dev/null | grep -q "^$1 $2 [a-z]* $NS/${CLUSTER_OF[$2]} "; }

# The threshold in the loaded rule (seconds), from its expression. Prometheus
# loads rules up to a minute after an apply (2026-11-04: resolve run 0 s
# after it still saw the test threshold): wait for the expected one.
threshold() {
  prom_api rules | jq -r '.data.groups[].rules[] | select(.name == "MySQLBackupTooOld") | .query' |
    grep -oE '> [0-9.e+]+' | head -1 | tr -dc '0-9.e+' | awk '{printf "%d", $1}'
}
if [[ "$MODE" == fire ]]; then _expected() { local t; t="$(threshold)"; ((t > 0 && t < 3600)); }; else
  _expected() { (($(threshold) >= 86400)); }; fi
printf '  %s threshold loaded:' "$([[ "$MODE" == fire ]] && echo "a test" || echo "the real")"
wait_for 120 _expected || echo "  not after 120 s"
THRESHOLD="$(threshold)"
echo "  threshold in the loaded rules: ${THRESHOLD:-?} s"
if [[ "$MODE" == fire ]]; then
  ((THRESHOLD > 0 && THRESHOLD < 3600)) || die "not a test threshold: terraform apply -var backup_alert_after_hours=0.1 (relational clusters root) first"
else
  ((THRESHOLD >= 86400)) || die "still the test threshold: terraform apply (relational clusters root) first"
  for a in "${ALERTS[@]}"; do
    logged firing "$a" || die "no 'firing $a' in alert-log in the last hour: nothing to resolve (run fire first)"
  done
fi
PG_AGE="$(prom_q "time() - max(barman_cloud_cloudnative_pg_io_last_available_backup_timestamp{namespace=\"$NS\"})" | jq -r '.data.result[0].value[1] // "" | tonumber? // empty | floor')"
MY_AGE="$(prom_q "time() - max(pxc_backup_completed_timestamp_seconds{namespace=\"$NS\",state=\"Succeeded\"})" | jq -r '.data.result[0].value[1] // "" | tonumber? // empty | floor')"
echo "  newest backups: pg ${PG_AGE:-?} s old, mysql ${MY_AGE:-?} s old"
PG_AGE="${PG_AGE:-0}"
MY_AGE="${MY_AGE:-0}"

if [[ "$MODE" == fire ]]; then
  # The younger backup crosses the threshold last, then 10 min of "for"
  YOUNGEST=$((PG_AGE < MY_AGE ? PG_AGE : MY_AGE))
  WAIT=$((THRESHOLD - YOUNGEST > 0 ? THRESHOLD - YOUNGEST : 0))
  WAIT=$((WAIT + 600 + 120))
  ((WAIT > 1800)) && WAIT=1800
  echo "  expect both firing within $((WAIT / 60)) min"
  _both() { for a in "${ALERTS[@]}"; do [[ "$(alert_state "$a")" == firing ]] || return 1; done; }
  printf '  both firing in Prometheus:'
  wait_for "$WAIT" _both || echo "  not after $WAIT s"
  for a in "${ALERTS[@]}"; do
    s="$(alert_state "$a")"
    if [[ "$s" == firing ]]; then pass "$a firing" "$s"; else fail "$a firing" "${s:-inactive}"; fi
    n="$(in_alertmanager "$a")"
    if ((n > 0)); then pass "$a held by Alertmanager" "$n"; else fail "$a held by Alertmanager" "0"; fi
    _logged() { logged firing "$a"; }
    printf "  %s in alert-log:" "$a"
    if wait_for "$NOTIFY_WAIT" _logged; then pass "$a notified (alert-log)" "$(k -n monitoring logs deploy/alert-log --since-time="$START" | grep -m1 "^firing $a [a-z]* $NS/")"; else
      fail "$a notified (alert-log)" "no 'firing $a' line after $NOTIFY_WAIT s"; fi
  done
  OTHERS="$(prom_q "ALERTS{alertstate=\"firing\",namespace=\"$NS\",alertname=~\".*(BackupFailed|WALArchive|BinlogCollector).*\"}" | jq -r '[.data.result[].metric.alertname] | unique | join(" ")')"
  if [[ -z "$OTHERS" ]]; then pass "No other backup alert firing" "none"; else fail "No other backup alert firing" "$OTHERS"; fi
  echo
  echo "  Next: terraform apply (relational clusters root, back to 192 h), then $0 resolve"
else
  _none() { for a in "${ALERTS[@]}"; do [[ "$(alert_state "$a")" != firing ]] || return 1; done; }
  printf '  both cleared in Prometheus:'
  wait_for 300 _none || echo "  not after 300 s"
  for a in "${ALERTS[@]}"; do
    s="$(alert_state "$a")"
    if [[ "$s" != firing ]]; then pass "$a no longer firing" "${s:-inactive}"; else fail "$a no longer firing" "$s"; fi
    _logged() { logged resolved "$a"; }
    printf "  %s resolved in alert-log:" "$a"
    if wait_for "$NOTIFY_WAIT" _logged; then pass "$a resolved (alert-log)" "$(k -n monitoring logs deploy/alert-log --since-time="$START" | grep -m1 "^resolved $a [a-z]* $NS/")"; else
      fail "$a resolved (alert-log)" "no 'resolved $a' line after $NOTIFY_WAIT s"; fi
  done
fi
summary "backup alert checks"
