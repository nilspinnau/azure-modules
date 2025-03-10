
resource "azurerm_monitor_diagnostic_setting" "default" {
  count = var.monitoring.enabled == true ? 1 : 0

  name                           = "localmonitoring"
  target_resource_id             = azurerm_storage_account.default.id
  log_analytics_destination_type = "Dedicated"
  log_analytics_workspace_id     = var.monitoring.config.workspace.resource_id

  metric {
    category = "Availability"
    enabled  = true
  }
}