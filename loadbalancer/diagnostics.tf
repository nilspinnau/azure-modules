
resource "azurerm_monitor_diagnostic_setting" "loadblancer" {
  count = var.monitoring.enabled == true ? 1 : 0

  name                           = "localmonitoring"
  target_resource_id             = azurerm_lb.lb.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id     = var.monitoring.config.workspace.resource_id

  enabled_log {
    category = "LoadBalancerHealthEvent"
  }

  metric {
    category = "VipAvailability"
    enabled  = true
  }

  metric {
    category = "DipAvailability"
    enabled  = true
  }
}
