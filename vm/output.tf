output "vm_ids" {
  value = local.is_windows == true ? [for vm in azurerm_windows_virtual_machine.win_vm : vm.id] : [for vm in azurerm_linux_virtual_machine.linux_vm : vm.id]
}


output "vms" {
  value = local.is_windows == true ? {
    for k, vm in azurerm_windows_virtual_machine.win_vm : k => {
      id   = vm.id
      name = vm.name
      zone = vm.zone
      os_disk = {
        id                     = data.azurerm_managed_disk.win_os_disk[k].id
        name                   = data.azurerm_managed_disk.win_os_disk[k].name
        storage_account_type   = data.azurerm_managed_disk.win_os_disk[k].storage_account_type
        disk_encryption_type   = var.disk_encryption.config.type
        disk_encryption_set_id = data.azurerm_managed_disk.win_os_disk[k].disk_encryption_set_id
      }
      resource_group_name  = var.resource_group_name
      network_interface_id = azurerm_network_interface.nic.0.id
      managed_disks        = module.windows_disks[k].data_disks
    }
    } : {
    for k, vm in azurerm_linux_virtual_machine.linux_vm : k => {
      id   = vm.id
      name = vm.name
      zone = vm.zone
      os_disk = {
        id                     = data.azurerm_managed_disk.linux_os_disk[k].id
        name                   = data.azurerm_managed_disk.linux_os_disk[k].name
        storage_account_type   = data.azurerm_managed_disk.linux_os_disk[k].storage_account_type
        disk_encryption_type   = var.disk_encryption.config.type
        disk_encryption_set_id = data.azurerm_managed_disk.linux_os_disk[k].disk_encryption_set_id
      }
      resource_group_name  = var.resource_group_name
      network_interface_id = azurerm_network_interface.nic.0.id
      managed_disks        = module.linux_disks[k].data_disks
      # managed_disks        = { for x, disk in module.linux_disks[k].data_disks : disk.lun => merge(disk, {disk_encryption_type = var.disk_encryption.config.type}) }
    }
  }
}



output "privatelink" {
  value = {
    alias = try(azurerm_private_link_service.default.0.alias, null)
    id    = try(azurerm_private_link_service.default.0.id, null)
  }
}