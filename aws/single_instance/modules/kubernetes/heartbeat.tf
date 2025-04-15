# File 47: ../../modules/kubernetes/heartbeat.tf

resource "kubernetes_deployment" "heartbeat" {
  metadata {
    name      = "heartbeat-app"
    namespace = kubernetes_namespace.namespaces["app1"].metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "heartbeat" }
    }
    template {
      metadata {
        labels = { app = "heartbeat" }
      }
      spec {
        container {
          name  = "heartbeat"
          image = "nginx:latest"
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          resources {
            limits = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "200m", memory = "256Mi" }
          }
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config.metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret.metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
}
