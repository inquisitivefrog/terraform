#!/usr/bin/env bash
# SSH to a single_instance EC2 instance. The private instance is reached
# through the public one (ProxyJump); no key is stored on either instance.
# Usage: ./ssh_ec2.sh dev|prod [public|private]   (default: public)
# Docs: single_instance/docs/KUBECTL.md, "Reaching the EC2 instances"

set -euo pipefail
source "$(dirname "$0")/aws_env.sh"

env=${1:-}
target=${2:-public}
key=~/.ssh/aws_ssh # key pair "blue-elephant" in us-east-2, both envs
case "$env" in
  dev | prod) ;;
  *)
    echo "Usage: $0 dev|prod [public|private]" >&2
    exit 1
    ;;
esac

env_dir="$(cd "$(dirname "$0")/../single_instance/environments/$env" && pwd)"
cd "$env_dir"

# Read an attribute of an instance from Terraform state.
attr() {
  terraform state show -no-color "module.compute.aws_instance.$1" |
    awk -v k="$2" '$1 == k { gsub(/"/, "", $3); print $3; exit }'
}

pub=$(attr public-ec2 public_ip)

# Load the key into the agent once, so the jump host can use it too.
ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$key" | awk '{print $2}')" ||
  ssh-add "$key"

case "$target" in
  public)
    echo "+ ssh ubuntu@$pub"
    exec ssh "ubuntu@$pub"
    ;;
  private)
    priv=$(attr private-ec2 private_ip)
    echo "+ ssh -J ubuntu@$pub ubuntu@$priv"
    exec ssh -J "ubuntu@$pub" "ubuntu@$priv"
    ;;
  *)
    echo "Usage: $0 dev|prod [public|private]" >&2
    exit 1
    ;;
esac
