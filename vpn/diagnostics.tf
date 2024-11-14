
data "azurerm_monitor_diagnostic_categories" "vpn" {
  resource_id = azurerm_virtual_network_gateway.default.id
}

resource "azurerm_monitor_diagnostic_setting" "vpn" {
  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.vpn.resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.vpn.log_category_types
    content {
      category = enabled_log.value
    }
  }
}


data "azurerm_monitor_diagnostic_categories" "public_ip" {
  for_each = var.ip_configuration

  resource_id = azurerm_public_ip.default[each.key].id
}

resource "azurerm_monitor_diagnostic_setting" "public_ip" {
  for_each = var.ip_configuration

  name                           = "diagnostic_setting"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.public_ip[each.key].resource_id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.public_ip[each.key].log_category_types
    content {
      category = enabled_log.value
    }
  }
}

####################################################
# dashboard
####################################################

locals {
  dashboard_vars = {
    GATEWAY_NAME = azurerm_virtual_network_gateway.default.name
    GATEWAY_ID   = azurerm_virtual_network_gateway.default.id
    LOCATION     = var.location
  }
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
}

resource "azurerm_portal_dashboard" "default" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                 = "db-vpn-${var.resource_suffix}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}