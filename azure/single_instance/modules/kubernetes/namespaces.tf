# modules/kubernetes/namespaces.tf
# Ported from aws/single_instance/modules/kubernetes; cloud-neutral apart
# from ingress.tf. Who may do what is Azure RBAC
# (modules/identity), not Kubernetes RoleBindings.

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(var.namespaces)
  metadata {
    name = each.key
  }
}
