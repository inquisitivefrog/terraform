# modules/kubernetes/quotas.tf

resource "kubernetes_resource_quota_v1" "quota" {
  for_each = toset(var.namespaces)
  metadata {
    namespace = kubernetes_namespace_v1.namespaces[each.key].metadata[0].name
    name      = "${each.key}-quota"
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "4Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "8Gi"
      "pods"            = "10"
    }
  }
}
