output "disk" {
  value = {
    id                     = azurerm_managed_disk.default.id
    name                   = azurerm_managed_disk.default.name
    lun                    = var.lun
    disk_encryption_type   = var.disk_encryption_type
    storage_account_type   = var.disk_storage_type
    disk_encryption_set_id = var.disk_encryption_set_id
    caching                = var.caching
  }
}