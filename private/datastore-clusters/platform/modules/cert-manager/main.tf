# cert-manager: issues and renews TLS certificates in the cluster from
# Certificate and Issuer resources. The Barman Cloud plugin (PostgreSQL
# backups) needs it: the CloudNativePG operator and the plugin talk over
# mutual TLS, and the plugin's chart asks cert-manager for both certificates.
# The databases keep their own operator-made certificates.
# See docs/BACKUPS.md.
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.chart_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true

  values = [yamlencode({
    # The chart installs its CRDs (Certificate, Issuer, ...) and keeps them on
    # uninstall: deleting them would delete every certificate in the cluster.
    crds = { enabled = true, keep = true }

    # Three small Deployments: the controller, the webhook that validates
    # cert-manager resources, and the cainjector that writes CA bundles into
    # webhooks. Requests from their typical use; no CPU limit (it throttles).
    resources = {
      requests = { cpu = "10m", memory = "64Mi" }
      limits   = { memory = "256Mi" }
    }
    webhook = {
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { memory = "128Mi" }
      }
    }
    cainjector = {
      resources = {
        requests = { cpu = "10m", memory = "64Mi" }
        limits   = { memory = "256Mi" }
      }
    }
    # The post-install Job that waits for the API to answer.
    startupapicheck = {
      resources = {
        requests = { cpu = "10m", memory = "32Mi" }
        limits   = { memory = "64Mi" }
      }
    }
  })]
}
