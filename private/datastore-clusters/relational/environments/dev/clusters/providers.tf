terraform {
  required_version = ">= 1.11.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.3.0"
    }
  }
  backend "local" {}
}

data "terraform_remote_state" "platform" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../platform/environments/dev/cluster/terraform.tfstate"
  }
}

# The backup store (outside the cluster): its endpoint and bucket names. Its
# keys are not in that state; backup_secrets.sh puts them in Secrets.
data "terraform_remote_state" "backup_store" {
  backend = "local"
  config = {
    path = "${path.module}/../../../../platform/environments/dev/backup-store/terraform.tfstate"
  }
}

# Explicit kubeconfig file and context: never ~/.kube/config or its
# current context (grid-meter's included).
provider "kubernetes" {
  config_path    = data.terraform_remote_state.platform.outputs.kubeconfig_path
  config_context = data.terraform_remote_state.platform.outputs.context_name
}
