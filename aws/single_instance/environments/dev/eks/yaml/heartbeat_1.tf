resource "kubernetes_deployment" "heartbeat_dev1" {
  provider = kubernetes.dev1
  metadata {
    name      = "heartbeat-app"
    namespace = kubernetes_namespace.app1_dev1.metadata[0].name
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
        containers {
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
        }
      }
    }
  }
}

# Repeat for dev2 and dev3
resource "kubernetes_deployment" "heartbeat_dev2" {
  provider = kubernetes.dev2
  metadata {
    name      = "heartbeat-app"
    namespace = kubernetes_namespace.app1_dev2.metadata[0].name
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
        containers {
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
        }
      }
    }
  }
}

resource "kubernetes_deployment" "heartbeat_dev3" {
  provider = kubernetes.dev3
  metadata {
    name      = "heartbeat-app"
    namespace = kubernetes_namespace.app1_dev3.metadata[0].name
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
        containers {
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
        }
      }
    }
  }
}
