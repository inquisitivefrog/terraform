#!/usr/bin/env bash
# SSH to a gcp/single_instance VM through Identity-Aware Proxy (works with the
# PIA VPN, which drops port 22). The private VM is reached through the public
# one; OS Login uses your Google identity, so no key is stored on the VMs.
# Usage: ./ssh_vm.sh dev|prod [public|private]   (default: public)
# Docs: ../README.gcloud.md, "SSH"

set -euo pipefail

env=${1:-}
target=${2:-public}
case "$env" in
  dev | prod) ;;
  *)
    echo "Usage: $0 dev|prod [public|private]" >&2
    exit 1
    ;;
esac

env_dir="$(cd "$(dirname "$0")/../single_instance/environments/$env" && pwd)"
cd "$env_dir"

project=$(terraform output -raw project_id)
zone=$(terraform output -raw zone)
public="public-vm-$env"

case "$target" in
  public)
    echo "+ gcloud compute ssh $public --zone $zone --project $project --tunnel-through-iap"
    exec gcloud compute ssh "$public" --zone "$zone" --project "$project" --tunnel-through-iap
    ;;
  private)
    key=~/.ssh/google_compute_engine # created and registered by gcloud compute ssh
    if [ ! -f "$key" ]; then
      echo "No $key yet: run '$0 $env public' once first." >&2
      exit 1
    fi
    user=$(gcloud compute os-login describe-profile --format='value(posixAccounts[0].username)')
    priv=$(terraform output -raw private_vm_ip)
    tunnel="gcloud compute start-iap-tunnel $public 22 --listen-on-stdin --zone $zone --project $project --verbosity=error"
    echo "+ ssh $user@$priv via $public (IAP)"
    exec ssh -i "$key" -o StrictHostKeyChecking=accept-new \
      -o ProxyCommand="ssh -i $key -o StrictHostKeyChecking=accept-new -o ProxyCommand='$tunnel' -W %h:%p $user@$public" \
      "$user@$priv"
    ;;
  *)
    echo "Usage: $0 dev|prod [public|private]" >&2
    exit 1
    ;;
esac
