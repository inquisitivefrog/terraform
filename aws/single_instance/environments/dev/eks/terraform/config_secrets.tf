resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app1.metadata[0].name
  }
  data = {
    "APP_ENV" = "dev"
    "LOG_LEVEL" = "info"
  }
}

resource "kubernetes_secret" "app_secret" {
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app1.metadata[0].name
  }
  data = {
    "API_KEY" = base64encode("my-secret-key")
  }
}
