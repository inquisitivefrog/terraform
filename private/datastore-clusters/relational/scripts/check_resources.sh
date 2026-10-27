#!/usr/bin/env bash
# Confirm the relational category (PostgreSQL on CloudNativePG, MySQL on
# Percona XtraDB Cluster) exists and is configured as intended, by asking
# Kubernetes and the databases rather than trusting "Apply complete".
# The platform has its own check: ../../platform/scripts/check_resources.sh
# Usage: private/datastore-clusters/relational/scripts/check_resources.sh [dev]   (read-only; run from anywhere)
# SQL runs inside the cluster with kubectl exec; passwords are read from the
# operators' Secrets and passed on stdin, never printed or put on a command line.

set -uo pipefail
source "$(dirname "$0")/../../../scripts/private_env.sh" # use_cluster, k, CTX
source "$(dirname "$0")/../../../scripts/checks.sh"      # expect, match, refused, summary
ENV="${1:-dev}"
NS="relational"
PG="pg"
MY="mysql"
ZONES="dc1-a dc1-b dc1-c"

secret() { k -n "$NS" get secret "$1" -o jsonpath="{.data.$2}" | base64 -d; }

# zones <label selector>: sorted, space-separated zones of the nodes running the selected pods
zones() {
  local node
  for node in $(k -n "$NS" get pods -l "$1" -o jsonpath='{.items[*].spec.nodeName}'); do
    k get node "$node" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}'
  done | sort | tr '\n' ' ' | sed 's/ $//'
}

# pg_local <sql>: as postgres on the primary, over its local socket
pg_local() { k -n "$NS" exec "$PG_PRIMARY" -c postgres -- psql -XAtq -d appdb -c "$1"; }

# pg_app <service> <sslmode> <sql>: as the application role, through a Service
pg_app() {
  k -n "$NS" exec -i "$PG_PRIMARY" -c postgres -- sh -c \
    'read -r PGPASSWORD; export PGPASSWORD; exec psql -XAtq "host=$0 user=app dbname=appdb sslmode=$1 connect_timeout=5" -c "$2"' \
    "$1" "$2" "$3" <<<"$PG_APP_PW"
}

# my_sql <service> <ssl-mode> <sql>: as root, through a HAProxy Service
my_sql() {
  k -n "$NS" exec -i "$MY_POD" -c pxc -- sh -c \
    'read -r MYSQL_PWD; export MYSQL_PWD; exec mysql -uroot -h "$0" --ssl-mode="$1" --connect-timeout=5 -NBe "$2"' \
    "$1" "$2" "$3" <<<"$MY_ROOT_PW"
}

use_cluster "datastore-$ENV"
echo "== relational $ENV (namespace $NS, kind cluster $CLUSTER) =="

echo
echo "-- operators --"
expect "CloudNativePG operator available" "1" k -n cnpg-system get deploy -l app.kubernetes.io/name=cloudnative-pg -o jsonpath='{.items[0].status.availableReplicas}'
# Without one it is BestEffort: the first pod evicted, and then nothing fails PostgreSQL over.
expect "CloudNativePG operator memory request / limit" "128Mi 256Mi" k -n cnpg-system get deploy -l app.kubernetes.io/name=cloudnative-pg \
  -o jsonpath='{.items[0].spec.template.spec.containers[0].resources.requests.memory} {.items[0].spec.template.spec.containers[0].resources.limits.memory}'
expect "Percona PXC operator memory request / limit, no CPU limit" "128Mi 512Mi none" k -n pxc-operator get deploy pxc-operator \
  -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory} {.spec.template.spec.containers[0].resources.limits.memory} {.spec.template.spec.containers[0].resources.limits.cpu}none'
expect "Percona PXC operator available" "1" k -n pxc-operator get deploy -o jsonpath='{.items[0].status.availableReplicas}'
expect "PXC operator watches all namespaces" "all" sh -c "v=\$(kubectl --context $CTX -n pxc-operator get deploy \
  -o jsonpath='{.items[0].spec.template.spec.containers[0].env[?(@.name==\"WATCH_NAMESPACE\")].value}'); echo \"\${v:-all}\""

echo
if ! k get namespace "$NS" >/dev/null 2>&1; then
  echo "-- clusters: namespace $NS not found (not applied); skipped --"
else
  echo "-- PostgreSQL cluster $PG (CloudNativePG) --"
  PG_PRIMARY="$(k -n "$NS" get clusters.postgresql.cnpg.io "$PG" -o jsonpath='{.status.currentPrimary}' 2>/dev/null)"
  if [[ -z "$PG_PRIMARY" ]]; then
    fail "Cluster $PG" "not found or no primary yet"
  else
    PG_APP_PW="$(secret "$PG-app" password)"
    expect "Cluster healthy" "Cluster in healthy state" k -n "$NS" get clusters.postgresql.cnpg.io "$PG" -o jsonpath='{.status.phase}'
    expect "Three instances ready" "3" k -n "$NS" get clusters.postgresql.cnpg.io "$PG" -o jsonpath='{.status.readyInstances}'
    expect "Instances in three different zones" "$ZONES" zones "cnpg.io/cluster=$PG,cnpg.io/podRole=instance"
    expect "Primary is $PG_PRIMARY, alone in its role" "$PG_PRIMARY" k -n "$NS" get pods -l "cnpg.io/cluster=$PG,cnpg.io/instanceRole=primary" -o jsonpath='{.items[*].metadata.name}'
    expect "Both replicas streaming" "2" pg_local "select count(*) from pg_stat_replication where state = 'streaming'"
    match "Quorum synchronous commit (ANY 1 of the replicas)" '^ANY 1 \(' pg_local "show synchronous_standby_names"
    expect "Replicas in the quorum" "2" pg_local "select count(*) from pg_stat_replication where sync_state = 'quorum'"
    expect "PodDisruptionBudgets (primary, replicas)" "$PG $PG-primary" sh -c "kubectl --context $CTX -n $NS get pdb -l cnpg.io/cluster=$PG \
      -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ \$//'"
    expect "Writer endpoint $PG-rw: primary, over TLS" "false true" pg_app "$PG-rw" require \
      "select pg_is_in_recovery()::text || ' ' || ssl::text from pg_stat_ssl where pid = pg_backend_pid()"
    expect "Reader endpoint $PG-ro: a replica" "true" pg_app "$PG-ro" require "select pg_is_in_recovery()::text"
    refused "Unencrypted connection rejected" 'pg_hba\.conf rejects connection' pg_app "$PG-rw" disable "select 1"
    expect "Application database appdb owned by app" "app" pg_local "select pg_get_userbyid(datdba) from pg_database where datname = 'appdb'"
  fi

  echo
  echo "-- MySQL cluster $MY (Percona XtraDB Cluster) --"
  MY_POD="$(k -n "$NS" get pods -l "app.kubernetes.io/instance=$MY,app.kubernetes.io/component=pxc" \
    -o jsonpath='{range .items[?(@.status.containerStatuses[0].ready==true)]}{.metadata.name}{"\n"}{end}' 2>/dev/null | head -1)"
  if [[ -z "$MY_POD" ]]; then
    fail "Cluster $MY" "not found or no node ready"
  else
    MY_ROOT_PW="$(secret "$MY-secrets" root)"
    expect "Cluster ready" "ready" k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$MY" -o jsonpath='{.status.state}'
    expect "Three nodes ready" "3" k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$MY" -o jsonpath='{.status.pxc.ready}'
    expect "Three HAProxies ready" "3" k -n "$NS" get perconaxtradbclusters.pxc.percona.com "$MY" -o jsonpath='{.status.haproxy.ready}'
    expect "Nodes in three different zones" "$ZONES" zones "app.kubernetes.io/instance=$MY,app.kubernetes.io/component=pxc"
    expect "HAProxies in three different zones" "$ZONES" zones "app.kubernetes.io/instance=$MY,app.kubernetes.io/component=haproxy"
    expect "Galera cluster: 3 members, Primary component" "3 Primary" my_sql "$MY-haproxy" REQUIRED \
      "select group_concat(variable_value order by variable_name separator ' ') from performance_schema.global_status where variable_name in ('wsrep_cluster_size','wsrep_cluster_status')"
    match "Writer endpoint $MY-haproxy: one node, over TLS" "^$MY-pxc-[0-9]+ TLS" my_sql "$MY-haproxy" REQUIRED \
      "select concat(@@hostname, ' ', if(variable_value <> '', 'TLS', 'plain')) from performance_schema.session_status where variable_name = 'Ssl_cipher'"
    match "Reader endpoint $MY-haproxy-replicas answers" "^$MY-pxc-[0-9]+$" my_sql "$MY-haproxy-replicas" REQUIRED "select @@hostname"
    expect "require_secure_transport" "1" my_sql "$MY-haproxy" REQUIRED "select @@require_secure_transport"
    refused "Unencrypted connection rejected" 'ERROR 3159|insecure transport are prohibited' my_sql "$MY-haproxy" DISABLED "select 1"
    expect "Application user app with database appdb" "1 1" my_sql "$MY-haproxy" REQUIRED \
      "select concat((select count(*) from mysql.user where user = 'app'), ' ', (select count(*) from information_schema.schemata where schema_name = 'appdb'))"
    expect "PodDisruptionBudgets (nodes, HAProxies)" "2" sh -c "kubectl --context $CTX -n $NS get pdb -l app.kubernetes.io/instance=$MY --no-headers | wc -l | tr -d ' '"
  fi

  # Metrics in the shared Prometheus and the dashboards in Grafana. Right after
  # an apply, allow a minute for the first scrapes.
  echo
  if ! k get namespace monitoring >/dev/null 2>&1; then
    echo "-- metrics: namespace monitoring not found (platform services not applied); skipped --"
  else
    echo "-- metrics and dashboards --"
    expect "Prometheus scrapes every $PG instance" "3" prom_count "up{namespace=\"$NS\", job=\"$NS/$PG\"} == 1"
    expect "CloudNativePG operator scraped" "1" prom_count 'up{namespace="cnpg-system"} == 1'
    expect "mysqld_exporter sidecar ready on every node" "3 3" sh -c "kubectl --context $CTX -n $NS get pods -l app.kubernetes.io/instance=$MY,app.kubernetes.io/component=pxc \
      -o jsonpath='{range .items[*]}{.status.containerStatuses[?(@.name==\"mysqld-exporter\")].ready}{\"\\n\"}{end}' | grep -c true | xargs printf '%s 3'"
    expect "Every exporter logged in to its node (mysql_up)" "3" prom_value "sum(mysql_up{namespace=\"$NS\"})"
    expect "Prometheus sees 3 nodes in the Primary Component" "3" prom_value "sum(mysql_global_status_wsrep_cluster_status{namespace=\"$NS\"})"
    expect "Dashboards for Grafana's sidecar (CloudNativePG, MySQL / Galera)" "cnpg-grafana-dashboard $MY-grafana-dashboard" sh -c \
      "kubectl --context $CTX get configmap -A -l grafana_dashboard=1 -o jsonpath='{range .items[*]}{.metadata.name}{\"\\n\"}{end}' | grep -E '^(cnpg|$MY)-grafana-dashboard$' | sort | xargs"
  fi

  # The orders example app (environments/dev/app), once per engine.
  echo
  if ! k -n "$NS" get deploy orders-pg orders-mysql >/dev/null 2>&1; then
    echo "-- orders app: not deployed (environments/dev/app not applied); skipped --"
  else
    echo "-- orders app --"
    app_get() { k get --raw "/api/v1/namespaces/$NS/services/$1:http/proxy$2" 2>&1; }
    for APP in orders-pg orders-mysql; do
      expect "$APP: 2 pods ready" "2" k -n "$NS" get deploy "$APP" -o jsonpath='{.status.readyReplicas}'
      match "$APP: pods in 2 different zones" '^(dc1-a dc1-[bc]|dc1-b dc1-c)$' zones "app.kubernetes.io/name=orders,app.kubernetes.io/instance=$APP"
      match "$APP: healthy, database included" '"status":"UP"' app_get "$APP" /actuator/health
      match "$APP: schema migrated (customers readable through the reader)" '^\[' app_get "$APP" "/customers/ids?limit=1"
    done
    expect "Prometheus scrapes every app pod" "4" prom_count "up{namespace=\"$NS\", service=~\"orders-(pg|mysql)\"} == 1"
    expect "k6 script and Orders load dashboard" "orders-grafana-dashboard orders-k6" sh -c \
      "kubectl --context $CTX -n $NS get configmap orders-k6 orders-grafana-dashboard -o name | sed 's:.*/::' | sort | xargs"
  fi
fi

summary "relational resources"
