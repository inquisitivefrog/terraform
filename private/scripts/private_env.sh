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
