
data "azurerm_monitor_diagnostic_categories" "agw" {
  count = var.monitoring.enabled == true ? 1 : 0

  resource_id = azurerm_application_gateway.default.id
}

resource "azurerm_monitor_diagnostic_setting" "agw" {
  count = var.monitoring.enabled == true ? 1 : 0

  name                           = "diagnostic_setting"
  target_resource_id             = azurerm_application_gateway.default.id
  log_analytics_workspace_id     = var.monitoring.config.workspace.resource_id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.agw.0.log_category_types
    content {
      category = enabled_log.value
    }
  }
}