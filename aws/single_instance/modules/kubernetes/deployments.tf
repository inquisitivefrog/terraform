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
          image = "public.ecr.aws/nginx/nginx:1.25.2"
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          resources {
            limits   = { cpu = "200m", memory = "256Mi" }
            requests = { cpu = "100m", memory = "128Mi" }
          }
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config["app1"].metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret["app1"].metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map.app_config,
    kubernetes_secret.app_secret,
    kubernetes_namespace.namespaces
  ]
}

resource "kubernetes_service" "heartbeat" {
  metadata {
    name      = "heartbeat-service"
    namespace = kubernetes_namespace.namespaces["app1"].metadata[0].name
  }
  spec {
    selector = {
      app = "heartbeat"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.heartbeat]
}

resource "kubernetes_deployment" "monitor" {
  metadata {
    name      = "monitor-app"
    namespace = kubernetes_namespace.namespaces["app2"].metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "monitor" }
    }
    template {
      metadata {
        labels = { app = "monitor" }
      }
      spec {
        container {
          name  = "monitor"
          image = "public.ecr.aws/nginx/nginx:1.25.2"
          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          resources {
            limits   = { cpu = "200m", memory = "256Mi" }
            requests = { cpu = "100m", memory = "128Mi" }
          }
          env {
            name = "APP_ENV"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.app_config["app2"].metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secret["app2"].metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [
    kubernetes_config_map.app_config,
    kubernetes_secret.app_secret,
    kubernetes_namespace.namespaces
  ]
}

resource "kubernetes_service" "monitor" {
  metadata {
    name      = "monitor-service"
    namespace = kubernetes_namespace.namespaces["app2"].metadata[0].name
  }
  spec {
    selector = {
      app = "monitor"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
  depends_on = [kubernetes_deployment.monitor]
}
