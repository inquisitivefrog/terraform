# State goes in the tfstate environments account, encrypted with its Key
# Vault key (AWS: KMS alias/tfstate-dev; GCP: state-bucket-key).
subscription_id      = "8d75b8ef-999c-4f70-99a9-4eb0197f3a07" # bluedragon-sre
resource_group_name  = "bluedragon-tfstate-dev-a2oowcjc-rg"
storage_account_name = "bdtfstatedeva2oowcjc" # azure/tfstate/environments/dev: terraform output state_account_name
container_name       = "tfstate"
key                  = "single_instance/terraform.tfstate"
use_azuread_auth     = true
