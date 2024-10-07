
resource "azurerm_network_watcher_flow_log" "nsg_flow_logs" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if var.flow_logs.enabled == true && try(var.flow_logs.config.nsg_flow_logs, false) == true && subnet.enable_nsg == true
  }

  network_watcher_name = "NetworkWatcher_${var.az_region}"
  resource_group_name  = "NetworkWatcherRG"
  location             = var.az_region
  name                 = "flowlogs-nsg-${each.value.name}-${var.az_region}-${var.resource_postfix}"

  network_security_group_id = azurerm_network_security_group.default[each.key].id
  storage_account_id        = var.flow_logs.config.storage_account_id
  enabled                   = true

  dynamic "traffic_analytics" {
    for_each = var.flow_logs.config.traffic_analytics.enabled == true && var.flow_logs.config.traffic_analytics.workspace != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.flow_logs.config.traffic_analytics.workspace.workspace_id
      workspace_region      = var.flow_logs.config.traffic_analytics.workspace.location
      workspace_resource_id = var.flow_logs.config.traffic_analytics.workspace.resource_id
      interval_in_minutes   = 10
    }
  }

  version = 2

  retention_policy {
    enabled = true
    days    = 7
  }
}