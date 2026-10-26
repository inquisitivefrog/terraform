terraform {
  required_version = ">= 1.11.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.3.0"
    }
  }
  backend "local" {}
}

data "terraform_remote_state" "platform" {
  backend = "local"
  config = {
    path = "${path.module}/../cluster/terraform.tfstate"
  }
}

# Explicit kubeconfig file and context: never ~/.kube/config or its
# current context (grid-meter's included).
provider "helm" {
  kubernetes = {
    config_path    = data.terraform_remote_state.platform.outputs.kubeconfig_path
    config_context = data.terraform_remote_state.platform.outputs.context_name
  }
}
