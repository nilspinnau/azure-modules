
output "vm" {
  value = {
    id                    = local.vm.id
    name                  = local.vm.name
    identity              = local.vm.identity
    zone                  = local.vm.zone
    os_disk               = local.os_disk
    resource_group_name   = var.resource_group_name
    network_interface_ids = local.network_interface_ids
    managed_disks         = local.disks
  }
}

output "privatelink" {
  value = {
    alias = try(azurerm_private_link_service.default.0.alias, null)
    id    = try(azurerm_private_link_service.default.0.id, null)
  }
}