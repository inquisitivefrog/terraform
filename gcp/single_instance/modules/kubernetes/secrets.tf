# modules/kubernetes/secrets.tf

resource "kubernetes_config_map_v1" "app_config" {
  for_each = toset(var.namespaces)
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace_v1.namespaces[each.key].metadata[0].name
  }
  data = {
    "APP_ENV"   = var.env
    "LOG_LEVEL" = "info"
  }
}

# The provider base64-encodes data itself (the AWS version encoded twice)
resource "kubernetes_secret_v1" "app_secret" {
  for_each = toset(var.namespaces)
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace_v1.namespaces[each.key].metadata[0].name
  }
  data = {
    "API_KEY" = "my-secret-key"
  }
}
