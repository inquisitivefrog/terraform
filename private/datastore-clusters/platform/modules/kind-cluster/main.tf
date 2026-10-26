# The "private cloud": a kind cluster on Docker Desktop. Each worker node is a
# container standing in for a zone of one data center (separate power,
# cooling and network feeds); the topology labels are what the database
# operators spread replicas across, as EKS nodes carry their AWS AZ.
# The control plane keeps its NoSchedule taint, so databases run only on the
# zone workers. Storage is kind's local-path provisioner: a volume lives on
# one node, like an EBS volume in one AZ.

locals {
  topology = { "topology.kubernetes.io/region" = var.region }
}

resource "kind_cluster" "this" {
  name            = var.name
  node_image      = var.node_image
  kubeconfig_path = var.kubeconfig_path
  wait_for_ready  = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role   = "control-plane"
      labels = local.topology
    }

    dynamic "node" {
      for_each = var.zones
      content {
        role   = "worker"
        labels = merge(local.topology, { "topology.kubernetes.io/zone" = node.value })
      }
    }
  }
}
