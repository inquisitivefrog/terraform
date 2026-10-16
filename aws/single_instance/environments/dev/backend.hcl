bucket         = "bluedragon-tfstate-admin-dev" # Match tfstate
key            = "single_instance/terraform.tfstate"
region         = "us-west-2"
use_lockfile   = true
encrypt        = true
kms_key_id     = "arn:aws:kms:us-west-2:084375569056:alias/tfstate-dev" # created by tfstate/environments/dev
