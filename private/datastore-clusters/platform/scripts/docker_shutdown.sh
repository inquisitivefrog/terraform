#!/bin/bash
# Stop the kind cluster and the backup store gracefully and quit Docker
# Desktop, e.g. before a reboot or to give the laptop its memory back (the
# Docker Desktop VM holds about 7 GB with the relational clusters up).
# Nothing is destroyed: the cluster, the backups, their volumes and the
# Terraform state stay. docker_restart.sh brings them back.
#
# Usage: docker_shutdown.sh [--keep-docker]   (--keep-docker: stop only the cluster and the store)
#
# Each node container gets 120 s to stop (Docker's default is 10 s, then
# SIGKILL), so PostgreSQL and MySQL shut down cleanly. All three Galera nodes
# stop together, so the restart goes through the PXC operator's
# full-cluster crash recovery.

set -uo pipefail
CLUSTER="datastore-dev"

if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop is not running: nothing to stop."
  exit 0
fi

running() { docker ps --filter "name=^$CLUSTER-$1" --format '{{.Names}}'; }

WORKERS="$(running worker)"
if [[ -n "$WORKERS" ]]; then
  echo "Stopping workers (databases first): $(echo "$WORKERS" | xargs)"
  # shellcheck disable=SC2086 # one name per word
  docker stop -t 120 $WORKERS >/dev/null
fi
if [[ -n "$(running control-plane)" ]]; then
  echo "Stopping $CLUSTER-control-plane"
  docker stop -t 120 "$CLUSTER-control-plane" >/dev/null
fi
# A node Docker could not stop is tried once more. If it still runs, stop
# here: quitting Docker Desktop would kill it without a clean shutdown
# (2026-10-28: "did not receive an exit event" on worker3, then the quit
# killed the MySQL writer).
LEFT="$(running '')"
if [[ -n "$LEFT" ]]; then
  echo "Still running, trying again: $(echo "$LEFT" | xargs)"
  # shellcheck disable=SC2086 # one name per word
  docker stop -t 120 $LEFT >/dev/null
fi
docker ps -a --filter "name=^$CLUSTER-" --format '  {{.Names}}: {{.Status}}'
LEFT="$(running '')"
if [[ -n "$LEFT" ]]; then
  echo "Could not stop $(echo "$LEFT" | xargs); Docker Desktop left running so nothing is killed." >&2
  echo "Try 'docker stop -t 120 <name>' or restart Docker Desktop from its menu, then rerun this." >&2
  exit 1
fi

# The backup store (environments/dev/backup-store), after the cluster so
# nothing is still writing to it. Stopped here, it stays stopped until
# docker_restart.sh starts it (restart policy unless-stopped).
if [[ -n "$(docker ps --filter name=^datastore-backups$ --format '{{.Names}}')" ]]; then
  echo "Stopping datastore-backups (the backup store)"
  docker stop -t 30 datastore-backups >/dev/null
fi

if [[ "${1:-}" == "--keep-docker" ]]; then
  exit 0
fi

echo "Quitting Docker Desktop"
osascript -e 'quit app "Docker Desktop"' 2>/dev/null || osascript -e 'quit app "Docker"'
for _ in $(seq 1 30); do
  pgrep -f com.apple.Virtualization.VirtualMachine >/dev/null || break
  sleep 2
done
if pgrep -f com.apple.Virtualization.VirtualMachine >/dev/null; then
  echo "Docker Desktop's VM is still running after 60 s: quit it from the menu bar."
  exit 1
fi
echo "Docker Desktop stopped; its memory is free (swap clears only on reboot)."
