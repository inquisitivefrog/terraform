#!/usr/bin/env bash
# SSH to an azure/single_instance VM. The private VM is reached through the
# public one (ProxyCommand); no private key is stored on either VM.
# Usage:
#   ./ssh_vm.sh dev|prod [public|private]                 interactive SSH
#   ./ssh_vm.sh dev|prod [public|private] --run 'cmd'      run a command through
#       the Azure API (az vm run-command): no SSH, works whatever the VPN does
# SSH_PORT=2222 uses the public VM's second sshd port.
# Key: ~/.ssh/bluedragon_azure (its .pub is on the VMs; see README.az.md).

set -euo pipefail

env=${1:-}
target=${2:-public}
case "$env" in
  dev | prod) ;;
  *)
    echo "Usage: $0 dev|prod [public|private] [--run 'command']" >&2
    exit 1
    ;;
esac
case "$target" in
  public | private) ;;
  *)
    echo "Usage: $0 dev|prod [public|private] [--run 'command']" >&2
    exit 1
    ;;
esac

env_dir="$(cd "$(dirname "$0")/../single_instance/environments/$env" && pwd)"
cd "$env_dir"

# terraform output -raw prints a multi-line warning (or errors) when the env
# isn't initialized or applied; a real value is one line.
tf_output() {
  local val
  val="$(terraform output -raw "$1" 2>/dev/null)" || val=""
  [[ "$val" == *$'\n'* ]] && val=""
  printf '%s' "$val"
}

S="$(tf_output subscription_id)"
RG="$(tf_output resource_group_name)"
if [[ -z "$S" || -z "$RG" ]]; then
  echo "No terraform outputs for $env: not applied yet (or run terraform init -backend-config=backend.hcl in $env_dir)." >&2
  exit 2
fi

if [[ "${3:-}" == "--run" ]]; then
  cmd="${4:?--run needs a command}"
  echo "+ az vm run-command invoke -g $RG -n $target-vm-$env --scripts '$cmd'" >&2
  az vm run-command invoke -g "$RG" -n "$target-vm-$env" --subscription "$S" \
    --command-id RunShellScript --scripts "$cmd" --query 'value[0].message' -o tsv 2>/dev/null
  exit 0
fi

KEY=~/.ssh/bluedragon_azure
PORT="${SSH_PORT:-22}"
user="$(tf_output ssh_user)"
pub="$(tf_output public_vm_ip)"
opts=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10)

if [[ "$target" == "public" ]]; then
  echo "+ ssh -p $PORT $user@$pub" >&2
  exec ssh "${opts[@]}" -p "$PORT" "$user@$pub"
fi

priv="$(tf_output private_vm_ip)"
echo "+ ssh $user@$priv via $user@$pub:$PORT" >&2
exec ssh "${opts[@]}" \
  -o ProxyCommand="ssh -i $KEY -o StrictHostKeyChecking=accept-new -p $PORT -W %h:%p $user@$pub" \
  "$user@$priv"
