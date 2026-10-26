output "namespace" {
  value = helm_release.kube_prometheus_stack.namespace
}

output "prometheus_remote_write_url" {
  description = "In-cluster URL k6 pushes results to"
  value       = "http://kube-prometheus-stack-prometheus.${helm_release.kube_prometheus_stack.namespace}.svc:9090/api/v1/write"
}

output "grafana" {
  description = "How to open Grafana from the laptop"
  value       = "kubectl -n ${helm_release.kube_prometheus_stack.namespace} port-forward svc/kube-prometheus-stack-grafana 3000:80, then http://localhost:3000 as admin; password in Secret kube-prometheus-stack-grafana key admin-password"
}
