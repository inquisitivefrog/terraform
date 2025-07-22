resource "helm_release" "this" {
  name             = var.helm_release_name
  repository       = var.helm_repository
  chart            = var.helm_chart
  namespace        = var.namespace
  timeout          = 600
  create_namespace = var.create_namespace
  version          = var.helm_version
  dynamic "set" {
    for_each = var.values
    content {
      name  = set.key
      value = set.value
    }
  }
  depends_on = [var.alb_controller_release]
}
