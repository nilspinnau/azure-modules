
# ##############################################
# # NSG
# ##############################################

resource "azurerm_network_security_group" "default" {
  for_each = {
    for k, subnet in var.subnets : k => subnet
    if subnet.enable_nsg == true
  }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name        = security_rule.key
      description = security_rule.value.description
      priority    = security_rule.value.priority

      direction = security_rule.value.direction
      access    = security_rule.value.access
      protocol  = title(lower(security_rule.value.protocol))

      source_port_range       = "*" # try(security_rule.value.source_port, "*")
      destination_port_ranges = security_rule.value.destination_port_ranges

      source_address_prefixes = security_rule.value.source_address_prefix == null ? coalesce(security_rule.value.source_address_prefixes, azurerm_virtual_network.default.address_space) : null

      destination_address_prefixes = security_rule.value.source_address_prefix == null ? coalesce(security_rule.value.destination_address_prefixes, azurerm_virtual_network.default.address_space) : null

      source_address_prefix      = coalesce(try(azurerm_subnet.default[security_rule.value.source_address_prefix].address_prefixes.0, null), security_rule.value.source_address_prefix, azurerm_subnet.default[each.key].address_prefixes.0)
      destination_address_prefix = coalesce(try(azurerm_subnet.default[security_rule.value.destination_address_prefix].address_prefixes.0, null), security_rule.value.destination_address_prefix, azurerm_subnet.default[each.key].address_prefixes.0)
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "default" {
  for_each = {
    for k, subnet in var.subnets : k => subnet
    if subnet.enable_nsg == true
  }

  subnet_id                 = azurerm_subnet.default[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}
