
data "azurerm_user_assigned_identity" "default" {
  for_each = { for k, id in var.identity_ids : k => id }

  name                = split("/", each.value)[length(split("/", each.value)) - 1]
  resource_group_name = split("/", split("resourceGroups/", each.value)[1])[0]
}


resource "azurerm_role_assignment" "dns" {
  for_each = { for k, id in var.identity_ids : k => id if var.private_dns_zone_id != null }

  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = data.azurerm_user_assigned_identity.default[each.key].principal_id
  scope                = var.private_dns_zone_id
}

resource "azurerm_role_assignment" "network" {
  for_each = { for k, id in var.identity_ids : k => id if var.default_node.subnet_id != null }

  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_user_assigned_identity.default[each.key].principal_id
  scope                = var.default_node.subnet_id
}

resource "azurerm_role_assignment" "acr_pull" {
  for_each = { for k, id in var.identity_ids : k => id if var.container_registry_id != null }

  role_definition_name = "AcrPull"
  scope                = var.container_registry_id
  principal_id         = data.azurerm_user_assigned_identity.default[each.key].principal_id
}