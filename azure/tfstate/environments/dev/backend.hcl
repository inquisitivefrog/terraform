subscription_id      = "8d75b8ef-999c-4f70-99a9-4eb0197f3a07" # bluedragon-sre
resource_group_name  = "bluedragon-tfstate-dev-rg"      # created by tfstate/bootstrap/dev
storage_account_name = "bdtfstatedev"
container_name       = "tfstate"
key                  = "tfstate/terraform.tfstate"
use_azuread_auth     = true # shared keys are disabled
