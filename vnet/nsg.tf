
# ##############################################
# # NSG
# ##############################################

resource "azurerm_network_security_group" "default" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
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
      destination_port_ranges = security_rule.value.destination_port_range != null ? security_rule.value.destination_port_ranges : null
      destination_port_range  = security_rule.value.destination_port_range

      source_address_prefixes      = security_rule.value.source_address_prefix != null ? security_rule.value.source_address_prefixes : null
      source_address_prefix        = security_rule.value.source_address_prefix
      destination_address_prefixes = security_rule.value.destination_address_prefix != null ? security_rule.value.destination_address_prefixes : null
      destination_address_prefix   = security_rule.value.destination_address_prefix
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
