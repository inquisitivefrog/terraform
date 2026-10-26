output "release" {
  description = "namespace/name@chart version"
  value       = "${helm_release.operator.namespace}/${helm_release.operator.name}@${helm_release.operator.version}"
}
