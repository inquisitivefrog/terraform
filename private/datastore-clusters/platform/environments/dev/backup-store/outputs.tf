output "endpoint_in_cluster" {
  value = module.backup_store.endpoint_in_cluster
}

output "endpoint_on_laptop" {
  value = module.backup_store.endpoint_on_laptop
}

output "buckets" {
  value = module.backup_store.buckets
}

output "keys_file" {
  value = module.backup_store.keys_file
}
