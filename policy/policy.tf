resource "azurerm_policy_definition" "default" {
  name         = var.name
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = var.name

  policy_rule = var.policy_rule
  parameters  = var.parameters
}

resource "azurerm_resource_group_policy_assignment" "default" {
  name                 = "assignment-${var.name}"
  resource_group_id    = var.scope
  policy_definition_id = azurerm_policy_definition.default.id
}