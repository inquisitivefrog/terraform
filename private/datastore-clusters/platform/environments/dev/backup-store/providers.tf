terraform {
  required_version = ">= 1.11.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.6.0"
    }
  }
  # Local state, git-ignored. No keys in it: they stay in keys_dir.
  backend "local" {}
}

# Talks to the Docker daemon (Docker Desktop) directly; no credentials.
provider "docker" {}
