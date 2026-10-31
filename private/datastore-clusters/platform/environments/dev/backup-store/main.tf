# The backup store for dev, outside the kind cluster: its own root, so
# destroying and rebuilding the cluster (../cluster) leaves the backups.
# Needs only Docker Desktop, and the keys from
# platform/scripts/backup_store_keys.sh; apply it before or after the cluster.
module "backup_store" {
  source = "../../../modules/backup-store"

  name     = "datastore-backups"
  image    = var.seaweedfs_image
  keys_dir = pathexpand(var.keys_dir)
}
