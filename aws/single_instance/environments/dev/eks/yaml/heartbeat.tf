resource "kubernetes_config_map" "app_config_dev1" {
  provider = kubernetes.dev1
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app1_dev1.metadata[0].name
  }
  data = {
    "APP_ENV"   = "dev"
    "LOG_LEVEL" = "info"
  }
}

resource "kubernetes_secret" "app_secret_dev1" {
  provider = kubernetes.dev1
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app1_dev1.metadata[0].name
  }
  data = {
    "API_KEY" = base64encode("my-secret-key")
  }
}

resource "kubernetes_deployment" "heartbeat_dev1" {
  provider = kubernetes.dev1
  # ... previous spec ...
  spec {
    # ... previous spec ...
    template {
      # ... previous spec ...
      spec {
        containers {
          # ... previous container ...
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config_dev1.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret_dev1.metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
}

# Repeat for dev2 and dev3
resource "kubernetes_config_map" "app_config_dev2" {
  provider = kubernetes.dev2
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app1_dev2.metadata[0].name
  }
  data = {
    "APP_ENV"   = "dev"
    "LOG_LEVEL" = "info"
  }
}

resource "kubernetes_secret" "app_secret_dev2" {
  provider = kubernetes.dev2
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app1_dev2.metadata[0].name
  }
  data = {
    "API_KEY" = base64encode("my-secret-key")
  }
}

resource "kubernetes_deployment" "heartbeat_dev2" {
  provider = kubernetes.dev2
  # ... previous spec ...
  spec {
    # ... previous spec ...
    template {
      # ... previous spec ...
      spec {
        containers {
          # ... previous container ...
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config_dev2.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret_dev2.metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "app_config_dev3" {
  provider = kubernetes.dev3
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace.app1_dev3.metadata[0].name
  }
  data = {
    "APP_ENV"   = "dev"
    "LOG_LEVEL" = "info"
  }
}

resource "kubernetes_secret" "app_secret_dev3" {
  provider = kubernetes.dev3
  metadata {
    name      = "app-secret"
    namespace = kubernetes_namespace.app1_dev3.metadata[0].name
  }
  data = {
    "API_KEY" = base64encode("my-secret-key")
  }
}

resource "kubernetes_deployment" "heartbeat_dev3" {
  provider = kubernetes.dev3
  # ... previous spec ...
  spec {
    # ... previous spec ...
    template {
      # ... previous spec ...
      spec {
        containers {
          # ... previous container ...
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config_dev3.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret_dev3.metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
}
