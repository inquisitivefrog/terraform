# Sourced by the scripts in this directory: the one AWS account, CLI profile
# and region this repo's tfstate and single_instance trees use.
#
#   source "$(dirname "$0")/aws_env.sh"
#
# Since 2026-10-22 everything runs in the Free-plan account below. An SCP from
# the organization's management account (100434099521) denies every region
# except us-east-2, so dev and prod share it. Never point these scripts at the
# grid-meter account (184375956348, profile grid-meter-freetier).

ACCOUNT_ID="650836812595"
export AWS_PROFILE="blue-elephant" # set here, not inherited, so a stray export can't redirect a script
export AWS_PAGER=""                # long output scrolls instead of stopping in less
declare -A REGION=([dev]=us-east-2 [prod]=us-east-2)
REGIONS=(us-east-2) # each distinct region in REGION, for whole-account sweeps

# Stop unless the credentials belong to ACCOUNT_ID.
require_account() {
  local account
  account="$(aws sts get-caller-identity --query Account --output text 2>/dev/null)"
  if [[ "$account" != "$ACCOUNT_ID" ]]; then
    echo "Profile $AWS_PROFILE is account '${account:-none}', expected $ACCOUNT_ID. Stopping." >&2
    exit 1
  fi
}
