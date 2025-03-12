

resource "azurerm_mssql_virtual_network_rule" "default" {
  for_each = var.firewall_virtual_network_rules

  name      = each.key
  server_id = azurerm_mssql_server.default[local.name].id
  subnet_id = each.value
}

resource "azurerm_mssql_virtual_network_rule" "failover" {
  for_each = { for k, v in var.firewall_virtual_network_rules : k => v if var.failover != null }

  name      = each.key
  server_id = azurerm_mssql_server.default[local.failover_name].id
  subnet_id = each.value
}

resource "azurerm_mssql_firewall_rule" "default" {
  for_each = { for k, v in var.firewall_rules : k => v }

  name      = each.key
  server_id = azurerm_mssql_server.default[local.name].id

  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_firewall_rule" "failover" {
  for_each = { for k, v in var.firewall_rules : k => v }

  name      = each.key
  server_id = azurerm_mssql_server.default[local.failover_name].id

  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_outbound_firewall_rule" "default" {
  for_each = var.outbound_firewall_rules

  name      = each.value
  server_id = azurerm_mssql_server.default[local.name].id
}

resource "azurerm_mssql_outbound_firewall_rule" "failover" {
  for_each = { for k, v in var.outbound_firewall_rules : k => v if var.failover != null }

  name      = each.value
  server_id = azurerm_mssql_server.default[local.failover_name].id
}


resource "azurerm_private_endpoint" "private_endpoint" {
  for_each = { for k, v in var.private_endpoints : k => v }

  location                      = coalesce(each.value.location, var.location)
  name                          = coalesce(each.value.name, "pep-${each.value.subresource_name}-${each.value.is_failover ? local.failover_name : local.name}")
  resource_group_name           = coalesce(each.value.resource_group_name, var.resource_group_name)
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = coalesce(each.value.network_interface_name, "nic-${each.value.subresource_name}-${each.value.is_failover ? local.failover_name : local.name}")
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = coalesce(each.value.private_service_connection_name, "pse-${each.value.subresource_name}-${each.value.is_failover ? local.failover_name : local.name}")
    private_connection_resource_id = azurerm_mssql_server.default[each.value.is_failover ? local.failover_name : local.name].id
    subresource_names              = [each.value.subresource_name]
  }
  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = each.value.subresource_name
      subresource_name   = ip_configuration.value.subresource_name
    }
  }
}