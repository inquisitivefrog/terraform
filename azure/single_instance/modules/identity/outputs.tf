# modules/identity/outputs.tf

output "identities" {
  description = "Name => { id, principal_id, client_id } for every identity"
  value = { for k, v in azurerm_user_assigned_identity.this : k => {
    id           = v.id
    principal_id = v.principal_id
    client_id    = v.client_id
  } }
}
