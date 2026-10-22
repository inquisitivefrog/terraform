bucket         = "blue-elephant-tfstate-admin-dev" # Match tfstate
key            = "single_instance/terraform.tfstate"
region         = "us-east-2"
use_lockfile   = true
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-2:650836812595:alias/tfstate-dev" # created by tfstate/environments/dev
profile        = "blue-elephant"
