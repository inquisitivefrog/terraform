# backend.hcl
bucket         = "bluedragon-ecommerce-terraform-state"
key            = "ecommerce-k8s/terraform.tfstate"
region         = "us-east-1"
use_lockfile   = true
encrypt        = true
