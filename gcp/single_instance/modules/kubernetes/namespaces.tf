# modules/kubernetes/namespaces.tf
# Ported from aws/single_instance/modules/kubernetes; cloud-neutral apart
# from ingress.tf and the admin binding in rbac.tf.

resource "kubernetes_namespace_v1" "namespaces" {
  for_each = toset(var.namespaces)
  metadata {
    name = each.key
  }
}
