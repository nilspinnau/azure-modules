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

  traffic_analytics {
    enabled               = var.flow_logs.config.traffic_analytics.enabled
    workspace_resource_id = var.flow_logs.config.traffic_analytics.workspace.resource_id
    workspace_id          = var.flow_logs.config.traffic_analytics.workspace.workspace_id
    workspace_region      = var.flow_logs.config.traffic_analytics.workspace.location
  }

  retention_policy {
    enabled = true
    days    = try(var.flow_logs.retention_policy_days, 14)
  }

  tags = var.tags
}