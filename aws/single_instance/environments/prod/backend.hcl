bucket         = "blue-elephant-tfstate-admin-prod" # Match tfstate
key            = "single_instance/terraform.tfstate"
region         = "us-east-2"
use_lockfile   = true
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-2:650836812595:alias/tfstate-prod" # created by tfstate/environments/prod
profile        = "blue-elephant"
