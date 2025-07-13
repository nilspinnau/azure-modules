
resource "azurerm_log_analytics_workspace" "default" {
  name                = "law-appinsights-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  identity {
    type = "SystemAssigned"
  }
  immediate_data_purge_on_30_days_enabled = true
  local_authentication_enabled            = false
}

resource "azurerm_application_insights" "default" {
  name                          = "appinsights-${var.resource_suffix}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  application_type              = "other"
  local_authentication_disabled = false
  workspace_id                  = azurerm_log_analytics_workspace.default.id

  lifecycle {
    replace_triggered_by = [azurerm_log_analytics_workspace.default]
  }
}
