
##############################################
# Routing
##############################################

resource "azurerm_route_table" "default" {
  count = var.route_table.enabled == true ? 1 : 0

  name                = "rt-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  bgp_route_propagation_enabled = false

  tags = var.tags
}


resource "azurerm_route" "default" {
  for_each = { for k, v in var.route_table.routes : k => v if var.route_table.enabled == true }

  name                = each.key
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.default.0.name

  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}


resource "azurerm_subnet_route_table_association" "default" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.attach_route_table == true && var.route_table.enabled == true
  }

  subnet_id      = azurerm_subnet.default[each.key].id
  route_table_id = azurerm_route_table.default.0.id
}

