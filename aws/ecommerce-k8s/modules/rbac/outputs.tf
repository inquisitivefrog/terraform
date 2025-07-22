output "bluedragon_admin_role" {
  description = "Metadata of the bluedragon-admin cluster role"
  value       = kubernetes_manifest.bluedragon_admin_clusterrole.manifest.metadata
}
