#File 47: ../../modules/kubernetes/ingress.tf

resource "helm_release" "aws_alb_ingress_controller" {
  count      = var.enable_ingress ? 1 : 0
  name       = "aws-alb-ingress-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.0" # Use the latest stable version

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "region"
    value = "us-west-2"
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
}

resource "kubernetes_ingress_v1" "app_ingress" {
  count = var.enable_ingress ? 1 : 0
  metadata {
    name      = "app-ingress"
    namespace = "app1"
    annotations = {
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }
  spec {
    ingress_class_name = "alb"
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "heartbeat-service"
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
