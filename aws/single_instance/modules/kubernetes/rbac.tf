# File 41: ../../modules/kubernetes/rbac.tf

resource "kubernetes_role" "role" {
  for_each = { for role in var.rbac_roles : "${role.user}-${role.namespace}" => role }
  metadata {
    namespace = each.value.namespace
    name      = "${each.value.user}-role"
  }
  rule {
    api_groups = each.value.api_groups
    resources  = each.value.resources
    verbs      = each.value.verbs
  }
}
resource "kubernetes_role_binding" "binding" {
  for_each = { for role in var.rbac_roles : "${role.user}-${role.namespace}" => role }
  metadata {
    namespace = each.value.namespace
    name      = "${each.value.user}-binding"
  }
  subject {
    kind      = "User"
    name      = each.value.user
    api_group = "rbac.authorization.k8s.io"
  }
  role_ref {
    kind      = "Role"
    name      = kubernetes_role.role["${each.value.user}-${each.value.namespace}"].metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}
