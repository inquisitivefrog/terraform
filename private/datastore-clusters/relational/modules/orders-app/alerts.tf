# The user's view (RUNBOOKS.md 1): each operation's p95 latency and the
# error rate against the SLO, from the app's own request metrics (the same
# targets k6 checks, app/k6/orders.js). Server-side, so it works with or
# without a load test; quiet when there is almost no traffic.
locals {
  # op = [method, uri, p95 SLO in seconds]
  slo = {
    create = ["POST", "/orders", 0.2]
    read   = ["GET", "/orders/{id}", 0.1]
    search = ["POST", "/orders/_search", 0.3]
    update = ["PATCH", "/orders/{id}", 0.2]
    delete = ["DELETE", "/orders/{id}", 0.2]
  }
  app_sel = "namespace=\"${var.namespace}\",job=\"${var.name}\""
}

resource "kubernetes_manifest" "alerts" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "${var.name}-alerts"
      namespace = var.namespace
    }
    spec = {
      groups = [{
        name = var.name
        rules = concat(
          [for op, s in local.slo : {
            alert = "OrdersLatencySLO"
            expr = join(" ", [
              "histogram_quantile(0.95, sum by (le) (rate(http_server_requests_seconds_bucket{${local.app_sel},method=\"${s[0]}\",uri=\"${s[1]}\"}[5m]))) > ${s[2]}",
              "and on () sum(rate(http_server_requests_seconds_count{${local.app_sel},method=\"${s[0]}\",uri=\"${s[1]}\"}[5m])) > 0.05",
            ])
            for         = "5m"
            labels      = { severity = "warning", app = var.name, op = op }
            annotations = { summary = "${var.name} ${op}: p95 {{ $value | humanizeDuration }} over the ${s[2] * 1000} ms SLO" }
          }],
          [{
            alert = "OrdersErrorRate"
            expr = join(" ", [
              "sum(rate(http_server_requests_seconds_count{${local.app_sel},uri!~\"/actuator.*\",status=~\"5..\"}[5m]))",
              "/ sum(rate(http_server_requests_seconds_count{${local.app_sel},uri!~\"/actuator.*\"}[5m])) > 0.01",
            ])
            for         = "5m"
            labels      = { severity = "warning", app = var.name }
            annotations = { summary = "${var.name}: {{ $value | humanizePercentage }} of requests failing (SLO 1%)" }
          }],
        )
      }]
    }
  }
}
