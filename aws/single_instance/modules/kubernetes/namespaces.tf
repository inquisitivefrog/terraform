# File 40: ../../modules/kubernetes/namespaces.tf

resource "kubernetes_namespace" "namespaces" {
  for_each = toset(var.namespaces)

  metadata {
    name = each.key
  }
}
