# File 46: ../../modules/kubernetes/secrets.tf

resource "kubernetes_config_map" "app_config" {
  for_each = toset(["app1", "app2"])
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.namespaces[each.key].metadata[0].name
  }
  data = {
    "APP_ENV"   = "dev"
    "LOG_LEVEL" = "info"
  }
}

resource "kubernetes_secret" "app_secret" {
  for_each = toset(["app1", "app2"])
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.namespaces[each.key].metadata[0].name
  }
  data = {
    "API_KEY" = base64encode("my-secret-key")
  }
}
