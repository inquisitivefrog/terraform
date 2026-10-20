# modules/kubernetes/deployments.tf

locals {
  apps = {
    heartbeat = { namespace = "app1" }
    monitor   = { namespace = "app2" }
  }
}

resource "kubernetes_deployment_v1" "app" {
  for_each = local.apps
  metadata {
    name      = "${each.key}-app"
    namespace = kubernetes_namespace_v1.namespaces[each.value.namespace].metadata[0].name
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = each.key }
    }
    template {
      metadata {
        labels = { app = each.key }
      }
      spec {
        container {
          name  = each.key
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
                name = kubernetes_config_map_v1.app_config[each.value.namespace].metadata[0].name
                key  = "APP_ENV"
              }
            }
          }
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.app_secret[each.value.namespace].metadata[0].name
                key  = "API_KEY"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "app" {
  for_each = local.apps
  metadata {
    name      = "${each.key}-service"
    namespace = kubernetes_deployment_v1.app[each.key].metadata[0].namespace
  }
  spec {
    selector = { app = each.key }
    port {
      port        = 80
      target_port = 80
    }
    type = "ClusterIP"
  }
}
