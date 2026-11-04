variable "seaweedfs_image" {
  description = "SeaweedFS 4.48 (2026-09-28). MinIO's community edition stopped shipping images in 2025."
  type        = string
  default     = "chrislusf/seaweedfs:4.48"
}

variable "keys_dir" {
  description = "Folder of the store's keys and certificate (platform/scripts/backup_store_keys.sh and backup_store_tls.sh write them); outside the repo"
  type        = string
  default     = "~/.config/datastore-dev/backup-store"
}
