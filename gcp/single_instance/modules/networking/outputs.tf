# modules/networking/outputs.tf

output "private_vm_tag" {
  value = local.private_tag
}

output "public_vm_tag" {
  value = local.public_tag
}
