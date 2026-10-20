# modules/identity/identities.tf
# Azure counterpart of aws/single_instance/modules/identity (and gcp's)
# User-assigned managed identities stand in for IAM roles and users. Each env
# makes its own (names carry env), so dev and prod don't share identity.
# Personal Microsoft accounts can't create directory users or groups, so the
# sre and dba users are identities too. Managed identities can't impersonate
# each other; "Managed Identity Operator" on admin (they may attach it to a
# resource) is the nearest thing to AWS's AssumeAdminRolePolicy.

locals {
  identities = toset(["vm", "aks", "aca", "developer", "admin", "sre", "dba"])
}

resource "azurerm_user_assigned_identity" "this" {
  for_each            = local.identities
  name                = "id-${each.key}-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "operators_admin" {
  for_each             = toset(["sre", "dba"])
  scope                = azurerm_user_assigned_identity.this["admin"].id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.this[each.key].principal_id
}
