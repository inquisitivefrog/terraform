resource "kubernetes_namespace" "app1" {
  metadata {
    name = "app1"
  }
}

resource "kubernetes_namespace" "app2" {
  metadata {
    name = "app2"
  }
}
