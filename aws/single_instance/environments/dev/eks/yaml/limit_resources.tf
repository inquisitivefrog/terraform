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
          resources {
            limits = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "200m", memory = "256Mi" }
          }
        }
      }
    }
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
          resources {
            limits = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "200m", memory = "256Mi" }
          }
        }
      }
    }
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
          resources {
            limits = { cpu = "500m", memory = "512Mi" }
            requests = { cpu = "200m", memory = "256Mi" }
          }
        }
      }
    }
  }
}
