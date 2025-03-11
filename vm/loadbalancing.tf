

locals {
  agw_assignments = toset(flatten([
    for nic in var.network_interface : [
      for ipc in nic.ip_configuration : [
        for id in ipc.application_gateway_backend_address_pool_ids : {
          network_interface_id    = azurerm_network_interface.default[nic.key].id
          backend_address_pool_id = id
          ip_configuration_name   = ipc.key
      }]
    ]
  ]))
  lb_assignments = toset(flatten([
    for nic in var.network_interface : [
      for ipc in nic.ip_configuration : [
        for id in ipc.load_balancer_backend_address_pool_ids : {
          network_interface_id    = azurerm_network_interface.default[nic.key].id
          backend_address_pool_id = id
          ip_configuration_name   = ipc.key
      }]
    ]
  ]))
}

# we have an application gateway as a loadbalancer
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "default" {
  for_each = local.agw_assignments

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = each.value.backend_address_pool_id
}


# we have a normal loadbalancer as a loadbalancer
resource "azurerm_network_interface_backend_address_pool_association" "default" {
  for_each = local.lb_assignments

  network_interface_id    = each.value.network_interface_id
  ip_configuration_name   = each.value.ip_configuration_name
  backend_address_pool_id = each.value.backend_address_pool_id
}