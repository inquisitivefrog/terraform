terraform {
  required_version = ">= 1.11.0"
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11.0"
    }
  }
  # Local state: the private cloud has no S3. It is git-ignored; every
  # category root reads this root's outputs (kubeconfig, context) from it.
  backend "local" {}
}

# Talks to the Docker daemon (Docker Desktop) directly; no credentials.
provider "kind" {}
