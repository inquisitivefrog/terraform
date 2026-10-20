# modules/kubernetes/rbac.tf
# GKE maps Google identities to Kubernetes users by email.

locals {
  rbac_roles = { for role in var.rbac_roles : "${role.name}-${role.namespace}" => role }
}

resource "kubernetes_role_v1" "role" {
  for_each = local.rbac_roles
  metadata {
    namespace = kubernetes_namespace_v1.namespaces[each.value.namespace].metadata[0].name
    name      = "${each.value.name}-role"
  }
  rule {
    api_groups = each.value.api_groups
    resources  = each.value.resources
    verbs      = each.value.verbs
  }
}

resource "kubernetes_role_binding_v1" "binding" {
  for_each = local.rbac_roles
  metadata {
    namespace = kubernetes_role_v1.role[each.key].metadata[0].namespace
    name      = "${each.value.name}-binding"
  }
  subject {
    kind      = "User"
    name      = each.value.user
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role_v1.role[each.key].metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

# AWS: aws-auth mapped EC2Role to system:masters
resource "kubernetes_cluster_role_binding_v1" "admins" {
  for_each = var.cluster_admin_users
  metadata {
    name = "cluster-admin-${each.key}"
  }
  subject {
    kind      = "User"
    name      = each.value
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}
