


resource "azurerm_virtual_network_peering" "first" {
  count = var.peering.enabled == true ? 1 : 0

  name                      = "peer-${var.peering.config.first.virtual_network_name}-to-${var.peering.config.second.virtual_network_name}"
  resource_group_name       = var.peering.config.first.resource_group_name
  virtual_network_name      = var.peering.config.first.virtual_network_name
  remote_virtual_network_id = var.peering.config.second.virtual_network_id

  allow_forwarded_traffic      = var.peering.config.first.allow_forwarded_traffic
  allow_gateway_transit        = var.peering.config.first.allow_gateway_transit
  allow_virtual_network_access = var.peering.config.first.allow_virtual_network_access
}

resource "azurerm_virtual_network_peering" "second" {
  count = var.peering.enabled == true ? 1 : 0

  name                      = "peer-${var.peering.config.second.virtual_network_name}-to-${var.peering.config.first.virtual_network_name}"
  resource_group_name       = var.peering.config.second.resource_group_name
  virtual_network_name      = var.peering.config.second.virtual_network_name
  remote_virtual_network_id = var.peering.config.first.virtual_network_id

  allow_forwarded_traffic      = var.peering.config.second.allow_forwarded_traffic
  allow_gateway_transit        = var.peering.config.second.allow_gateway_transit
  allow_virtual_network_access = var.peering.config.second.allow_virtual_network_access
}