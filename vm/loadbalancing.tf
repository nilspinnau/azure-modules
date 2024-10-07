

# we have an application gateway as a loadbalancer
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "default" {
  count = var.loadbalancing.application_gateway.enabled == true && var.scale_set.enabled == false ? var.instance_count : 0

  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration.0.name
  backend_address_pool_id = var.loadbalancing.application_gateway.backend_address_pool_id
}


# we have a normal loadbalancer as a loadbalancer
resource "azurerm_network_interface_backend_address_pool_association" "default" {
  count = var.loadbalancing.loadbalancer.enabled == true && var.scale_set.enabled == false ? var.instance_count : 0

  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = azurerm_network_interface.nic[count.index].ip_configuration.0.name
  backend_address_pool_id = var.loadbalancing.loadbalancer.backend_address_pool_id
}