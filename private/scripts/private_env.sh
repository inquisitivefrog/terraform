# Sourced by the private/ scripts. The private cloud is Docker Desktop plus
# kind on this laptop: no account, no cost.
#
#   source "$(dirname "$0")/../../scripts/private_env.sh"
#   use_cluster datastore-dev       # sets KUBECONFIG and CTX for this script only
#
# Every kind cluster has its own kubeconfig file (~/.kube/kind-<name>) and
# every command names its context, so ~/.kube/config and its current
# context (grid-meter's included) are never read or changed.

require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running: start Docker Desktop (Settings > Resources: 8 GB memory or more)." >&2
    exit 1
  fi
}

# use_cluster <kind cluster name>: stop unless it exists and is reachable
use_cluster() {
  CLUSTER="$1"
  CTX="kind-$CLUSTER"
  export KUBECONFIG="$HOME/.kube/kind-$CLUSTER"
  require_docker
  if ! kind get clusters 2>/dev/null | grep -x "$CLUSTER" >/dev/null; then
    echo "No kind cluster $CLUSTER: apply private/datastore-clusters/platform/environments/dev/cluster first." >&2
    exit 1
  fi
  if ! kubectl --context "$CTX" get --raw /readyz >/dev/null 2>&1; then
    echo "kind cluster $CLUSTER exists but its API server ($KUBECONFIG, $CTX) does not answer." >&2
    exit 1
  fi
}

k() { kubectl --context "$CTX" "$@"; }

# runbook_log <logs dir> <name> "$@": copy everything the script prints into
# <dir>/<name>-<UTC time>.txt, the record of a run. A run that exits 0 keeps
# it (committed with the work); a failed run's log becomes -FAILED.txt,
# which git ignores. Only the latest of each name is kept: a pass deletes
# every older log of that name, a failure deletes older failures but keeps
# the last pass. A script called by one that already logs (a load test
# inside a runbook) writes into its caller's log instead of starting one.
runbook_log() {
  [[ -n "${RUNBOOK_LOG:-}" ]] && return
  mkdir -p "$1"
  export RUNBOOK_LOG
  _RUNBOOK_LOG_PREFIX="$(cd "$1" && pwd)/$2-"
  RUNBOOK_LOG="$_RUNBOOK_LOG_PREFIX$(date -u +%Y%m%d-%H%M%S).txt"
  # Two runs in the same second must not share (or rename) one log
  [[ -e "$RUNBOOK_LOG" || -e "${RUNBOOK_LOG%.txt}-FAILED.txt" ]] && RUNBOOK_LOG="${RUNBOOK_LOG%.txt}-$$.txt"
  exec > >(tee "$RUNBOOK_LOG") 2>&1
  trap '_runbook_log_end $?' EXIT
  echo "# $(basename "$0") ${*:3} ($(date -u +%Y-%m-%dT%H:%M:%SZ), kind cluster ${CLUSTER:-?})"
}
_runbook_log_end() {
  local f keep="$RUNBOOK_LOG"
  if [[ "$1" -ne 0 ]]; then
    keep="${RUNBOOK_LOG%.txt}-FAILED.txt"
    mv "$RUNBOOK_LOG" "$keep"
  fi
  # <name>-<digits>: "runbook-17-pg" must not match "runbook-17-pg-big-..."
  for f in "$_RUNBOOK_LOG_PREFIX"[0-9]*.txt; do
    [[ -e "$f" && "$f" != "$keep" ]] || continue
    [[ "$1" -eq 0 || "$f" == *-FAILED.txt ]] && rm -f "$f"
  done
  if [[ "$1" -eq 0 ]]; then
    echo "Log: $keep"
  else
    echo "Log (failed run, not committed): $keep"
  fi
}
