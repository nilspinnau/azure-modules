
# ##############################################
# # NSG
# ##############################################

resource "azurerm_network_security_group" "default" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.enable_nsg == true
  }

  name                = "nsg-${each.value.name}-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "security_rule" {
    for_each = {
      for k, rule in each.value.nsg_rules : k => rule
    }
    iterator = custom_rule
    content {
      name        = custom_rule.value.name
      description = custom_rule.value.description
      priority    = 1000 + custom_rule.key

      direction = custom_rule.value.direction
      access    = custom_rule.value.access
      protocol  = title(lower(custom_rule.value.protocol))

      source_port_range       = "*" # try(custom_rule.value.source_port, "*")
      destination_port_ranges = custom_rule.value.destination_port_ranges

      source_address_prefixes = custom_rule.value.source_address_prefix == null ? coalesce(custom_rule.value.source_address_prefixes, azurerm_virtual_network.default.address_space) : null

      destination_address_prefixes = custom_rule.value.source_address_prefix == null ? coalesce(custom_rule.value.destination_address_prefixes, azurerm_virtual_network.default.address_space) : null

      source_address_prefix      = coalesce(try(azurerm_subnet.default[custom_rule.value.source_address_prefix].address_prefixes.0, null), custom_rule.value.source_address_prefix, azurerm_subnet.default[each.key].address_prefixes.0)
      destination_address_prefix = coalesce(try(azurerm_subnet.default[custom_rule.value.destination_address_prefix].address_prefixes.0, null), custom_rule.value.destination_address_prefix, azurerm_subnet.default[each.key].address_prefixes.0)
    }
  }
}


resource "azurerm_subnet_network_security_group_association" "default" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.enable_nsg == true
  }

  subnet_id                 = azurerm_subnet.default[each.key].id
  network_security_group_id = azurerm_network_security_group.default[each.key].id
}
