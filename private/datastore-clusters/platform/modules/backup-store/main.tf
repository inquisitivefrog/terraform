# The backup store: an S3-compatible object store (SeaweedFS, `weed mini`)
# in its own Docker container, outside the kind cluster, so backups outlive
# the cluster the way S3 in another account outlives a lost one. Restoring
# into a rebuilt cluster (runbooks 8 and 10) depends on that.
#
# - Published on 127.0.0.1 only: the laptop reaches it at localhost, pods at
#   host.docker.internal (Docker Desktop's name for the laptop; pods can't
#   resolve container names on the kind network).
# - The data lives in a Docker volume: replacing the container (a new
#   image) keeps the backups; destroying this root deletes them.
# - One bucket and one key per engine, each key allowed only its own bucket;
#   nothing anonymous. The keys are in var.keys_dir (made by
#   platform/scripts/backup_store_keys.sh), mounted read-only: never in
#   Terraform state.
# - S3 over TLS only (https; plain http is refused): a certificate from our
#   own CA (platform/scripts/backup_store_tls.sh), in var.keys_dir too.
# - Encryption at rest: the key that protects every encrypted object's own
#   key comes from var.keys_dir/security.toml (SeaweedFS reads it from
#   /etc/seaweedfs), so it is not on the data volume beside the data.
#   Each bucket's default encryption is a store setting, made by
#   platform/scripts/backup_store_buckets.sh.
# docs/BACKUPS.md, "Where the keys are".
resource "docker_image" "seaweedfs" {
  name         = var.image
  keep_locally = true
}

resource "docker_volume" "data" {
  name = "${var.name}-data"
}

resource "docker_container" "store" {
  name    = var.name
  image   = docker_image.seaweedfs.image_id
  restart = "unless-stopped"

  # `weed mini`: master, volume server, filer and S3 in one process, tuned
  # for one node. It creates the buckets at start if they don't exist.
  command = [
    "mini",
    "-dir=/data",
    "-s3.config=/etc/seaweedfs/s3.json",
    "-s3.cert.file=/etc/seaweedfs/tls.crt",
    "-s3.key.file=/etc/seaweedfs/tls.key",
    # It would otherwise report usage to telemetry.seaweedfs.com once it
    # holds 10 GiB
    "-master.telemetry=false",
    "-bucket=${join(",", values(local.buckets))}",
  ]

  ports {
    internal = 8333
    external = var.port
    ip       = "127.0.0.1"
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/data"
  }

  volumes {
    host_path      = var.keys_dir
    container_path = "/etc/seaweedfs"
    read_only      = true
  }

  lifecycle {
    precondition {
      condition     = fileexists("${var.keys_dir}/s3.json") && fileexists("${var.keys_dir}/security.toml")
      error_message = "No ${var.keys_dir}/s3.json or security.toml: run platform/scripts/backup_store_keys.sh first."
    }
    precondition {
      condition     = fileexists("${var.keys_dir}/tls.crt") && fileexists("${var.keys_dir}/tls.key") && fileexists("${var.keys_dir}/ca.crt")
      error_message = "No certificate in ${var.keys_dir}: run platform/scripts/backup_store_tls.sh first."
    }
  }
}

locals {
  buckets = { for e in var.engines : e => "${e}-backups" }
}
