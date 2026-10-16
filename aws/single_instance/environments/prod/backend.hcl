bucket         = "bluedragon-tfstate-admin-prod" # Match tfstate
key            = "single_instance/terraform.tfstate"
region         = "us-west-1"
use_lockfile   = true
encrypt        = true
kms_key_id     = "arn:aws:kms:us-west-1:084375569056:alias/tfstate-prod" # created by tfstate/environments/prod
