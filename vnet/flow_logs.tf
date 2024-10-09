data "azurerm_network_watcher" "nw" {
  name                = "NetworkWatcher_${var.az_region}"
  resource_group_name = "NetworkWatcherRG"
}

resource "azapi_resource" "vnet_flow_logs" {
  count = var.flow_logs.enabled == true ? 1 : 0

  type      = "Microsoft.Network/networkWatchers/flowLogs@2023-11-01"
  name      = "logs-${azurerm_virtual_network.default.name}"
  location  = var.az_region
  parent_id = data.azurerm_network_watcher.nw.id

  body = jsonencode({
    properties = {
      enabled = true
      flowAnalyticsConfiguration = var.flow_logs.config.traffic_analytics.enabled ? {
        networkWatcherFlowAnalyticsConfiguration = {
          enabled               = var.flow_logs.config.traffic_analytics.enabled == true && var.flow_logs.config.traffic_analytics.workspace != null
          workspaceId          = var.flow_logs.config.traffic_analytics.workspace.workspace_id
          workspaceRegion      = var.flow_logs.config.traffic_analytics.workspace.location
          workspaceResourceId = var.flow_logs.config.traffic_analytics.workspace.resource_id
        }
      } : {}
      format = {
        type    = "JSON"
        version = 2
      }
      retentionPolicy = {
        days    = 30
        enabled = true
      }
      storageId        = var.flow_logs.config.storage_account_id
      targetResourceId = azurerm_virtual_network.default.id
    }
  })

  tags = var.tags
}