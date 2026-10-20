# modules/kubernetes/ingress.tf
# AKS's app routing add-on (managed NGINX) serves this class and gives it a
# public load balancer IP; no Helm chart or IAM role needed (AWS: ALB
# controller chart + role). Enabled with the cluster's web_app_routing block.

resource "kubernetes_ingress_v1" "app_ingress" {
  count = var.enable_ingress ? 1 : 0
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_service_v1.app["heartbeat"].metadata[0].namespace
  }
  spec {
    ingress_class_name = "webapprouting.kubernetes.azure.com"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.app["heartbeat"].metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
