# modules/tiller/main.tf

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  metadata {
    name = "tiller"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
}

resource "kubernetes_deployment" "tiller" {
  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"
    labels = {
      app  = "helm"
      name = "tiller"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app  = "helm"
        name = "tiller"
      }
    }
    template {
      metadata {
        labels = {
          app  = "helm"
          name = "tiller"
        }
      }
      spec {
        container {
          name  = "tiller"
          image = "ghcr.io/helm/tiller:v2.17.0"
          port {
            container_port = 44134
            name           = "tiller"
          }
          port {
            container_port = 44135
            name           = "http"
          }
          env {
            name  = "TILLER_NAMESPACE"
            value = "kube-system"
          }
          env {
            name  = "TILLER_HISTORY_MAX"
            value = "0"
          }
          liveness_probe {
            http_get {
              path = "/liveness"
              port = 44135
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
          }
          readiness_probe {
            http_get {
              path = "/readiness"
              port = 44135
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
          }
        }
        service_account_name = "tiller"
      }
    }
  }
}

resource "kubernetes_service" "tiller" {
  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"
    labels = {
      app  = "helm"
      name = "tiller"
    }
  }
  spec {
    selector = {
      app  = "helm"
      name = "tiller"
    }
    port {
      port        = 44134
      target_port = "tiller"
    }
  }
}
