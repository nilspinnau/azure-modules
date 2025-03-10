data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_${var.location}"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_network_watcher_flow_log" "vnet_flow_logs" {
  count = var.flow_logs != null ? 1 : 0

  name     = "logs-${azurerm_virtual_network.default.name}"
  location = var.location

  resource_group_name  = data.azurerm_network_watcher.nw.resource_group_name
  network_watcher_name = data.azurerm_network_watcher.nw.name

  target_resource_id = azurerm_virtual_network.default.id
  storage_account_id = var.flow_logs.storage_account_id

  enabled = true
  version = 2

  dynamic "traffic_analytics" {
    for_each = try(var.flow_logs.traffic_analytics != null, false) ? [var.flow_logs.traffic_analytics] : []
    content {
      enabled               = traffic_analytics.value.enabled
      workspace_resource_id = traffic_analytics.value.workspace_resource_id
      workspace_id          = traffic_analytics.value.workspace_id
      workspace_region      = traffic_analytics.value.workspace_region
    }
  }

  retention_policy {
    enabled = true
    days    = try(var.flow_logs.retention_policy_days, 14)
  }

  tags = var.tags
}