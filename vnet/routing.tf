
##############################################
# Routing
##############################################

resource "azurerm_route_table" "default" {
  count = var.route_table.enabled == true ? 1 : 0

  name                = "rt-${var.resource_postfix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "route" {
    for_each = var.route_table.routes
    content {
      address_prefix         = route.value.address_prefix
      name                   = route.value.name
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }

  tags = var.tags
}


resource "azurerm_subnet_route_table_association" "default" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
    if subnet.attach_route_table == true && var.route_table.enabled == true
  }

  subnet_id      = azurerm_subnet.default[each.key].id
  route_table_id = azurerm_route_table.default.0.id
}

