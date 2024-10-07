data "azurerm_monitor_diagnostic_categories" "default" {
  count = var.monitoring.enabled == true ? 1 : 0

  resource_id = azurerm_storage_account.default.id
}


resource "azurerm_monitor_diagnostic_setting" "default" {
  count = var.monitoring.enabled == true ? 1 : 0

  name                           = "localmonitoring"
  target_resource_id             = azurerm_storage_account.default.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id     = var.monitoring.config.workspace.resource_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.0.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.default.0.metrics
    content {
      category = metric.value
    }
  }
}