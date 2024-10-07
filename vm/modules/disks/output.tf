output "data_disks" {
  value = {
    for data_disk in var.additional_disks : data_disk.lun => {
      id                     = azurerm_managed_disk.vm_disks[data_disk.lun].id
      name                   = azurerm_managed_disk.vm_disks[data_disk.lun].name
      letter                 = data_disk.letter
      lun                    = data_disk.lun
      disk_encryption_type   = var.disk_encryption_type
      storage_account_type   = try(data_disk.type, var.disk_storage_type, "Standard_LRS")
      disk_encryption_set_id = var.disk_encryption_set_id
    }
  }
}