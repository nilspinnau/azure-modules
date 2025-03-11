
output "vm" {
  value = {
    (local.vm.name) = {
      id       = local.vm.id
      name     = local.vm.name
      identity = local.vm.identity
      zone     = local.vm.zone
      os_disk = {
        id                     = data.azurerm_managed_disk.win_os_disk[0].id
        name                   = data.azurerm_managed_disk.win_os_disk[0].name
        storage_account_type   = data.azurerm_managed_disk.win_os_disk[0].storage_account_type
        disk_encryption_type   = var.disk_encryption.type
        disk_encryption_set_id = var.disk_encryption.disk_encryption_set_id
      }
      resource_group_name   = var.resource_group_name
      network_interface_ids = local.network_interface_ids
      managed_disks         = local.disks
    }
  }
}

output "privatelink" {
  value = {
    alias = try(azurerm_private_link_service.default.0.alias, null)
    id    = try(azurerm_private_link_service.default.0.id, null)
  }
}