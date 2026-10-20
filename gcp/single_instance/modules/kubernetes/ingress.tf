# modules/kubernetes/ingress.tf
# GKE's built-in ingress controller creates an external HTTP load balancer;
# no Helm chart or IAM role needed (AWS: ALB controller chart + role).

resource "kubernetes_ingress_v1" "app_ingress" {
  count = var.enable_ingress ? 1 : 0
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_service_v1.app["heartbeat"].metadata[0].namespace
    annotations = {
      "kubernetes.io/ingress.class" = "gce"
    }
  }
  spec {
    default_backend {
      service {
        name = kubernetes_service_v1.app["heartbeat"].metadata[0].name
        port {
          number = 80
        }
      }
    }
  }
}
