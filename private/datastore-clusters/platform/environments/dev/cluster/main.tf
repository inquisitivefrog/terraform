# The private cloud for dev: one "data center" (region dc1) split into three
# independent zones, one Kubernetes worker each.
module "platform" {
  source = "../../../modules/kind-cluster"

  name            = "datastore-dev"
  node_image      = var.node_image
  kubeconfig_path = pathexpand(var.kubeconfig_path)
  region          = "dc1"
  zones           = ["dc1-a", "dc1-b", "dc1-c"]
}
