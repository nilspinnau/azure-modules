
data "azurerm_monitor_diagnostic_categories" "loadblancer" {
  count = var.monitoring.enabled == true ? 1 : 0

  resource_id = azurerm_lb.lb.id
}


resource "azurerm_monitor_diagnostic_setting" "loadblancer" {
  count = var.monitoring.enabled == true ? 1 : 0

  name                           = "localmonitoring"
  target_resource_id             = azurerm_lb.lb.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id     = var.monitoring.config.workspace.resource_id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.loadblancer.0.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.loadblancer.0.metrics
    content {
      category = metric.value
    }
  }
}
