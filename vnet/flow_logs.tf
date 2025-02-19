data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_${var.location}"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_network_watcher_flow_log" "vnet_flow_logs" {

  name     = "logs-${azurerm_virtual_network.default.name}"
  location = var.location

  resource_group_name  = data.azurerm_network_watcher.nw.resource_group_name
  network_watcher_name = data.azurerm_network_watcher.nw.name

  target_resource_id = azurerm_virtual_network.default.id
  storage_account_id = var.flow_logs.config.storage_account_id

  enabled = var.flow_logs.enabled
  version = 2

  dynamic "traffic_analytics" {
    for_each = var.flow_logs.config.traffic_analytics != null ? [var.flow_logs.config.traffic_analytics] : []
    content {
      enabled               = traffoc_analytics.value.enabled
      workspace_resource_id = traffoc_analytics.value.workspace.resource_id
      workspace_id          = traffoc_analytics.value.workspace.workspace_id
      workspace_region      = traffoc_analytics.value.workspace.location
    }
  }

  retention_policy {
    enabled = true
    days    = try(var.flow_logs.retention_policy_days, 14)
  }

  tags = var.tags
}