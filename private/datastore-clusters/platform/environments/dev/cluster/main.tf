# The private cloud for dev: one "data center" (region dc1) split into three
# independent zones, one Kubernetes worker each.
module "platform" {
  source = "../../../modules/kind-cluster"

  name            = "datastore-dev"
  node_image      = var.node_image
  kubeconfig_path = pathexpand(var.kubeconfig_path)
  region          = "dc1"
  zones           = ["dc1-a", "dc1-b", "dc1-c"]

  # 50 s by default: zone loss took ~61-64 s on pg and ~77 s for the app
  # (runbook 26, 2026-10-30). 20 s is two missed kubelet updates (every
  # 10 s), with room for Docker Desktop pauses.
  node_monitor_grace_period = "20s"
}
