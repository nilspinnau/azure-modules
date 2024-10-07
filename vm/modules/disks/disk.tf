
resource "azurerm_managed_disk" "vm_disks" {
  # we create x disks for each vm we create
  for_each = { for data_disk in var.additional_disks : data_disk.lun => data_disk }

  name                = "disk-${each.value.lun}-${each.value.letter}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  storage_account_type = try(each.value.type, var.disk_storage_type, "Standard_LRS")
  create_option        = try(each.value.create_option, "Empty")
  disk_size_gb         = each.value.disk_size

  disk_encryption_set_id = var.disk_encryption_set_id

  zone = var.zone

  public_network_access_enabled = false
  network_access_policy         = "DenyAll" # "AllowAll"

  tags = var.tags

  lifecycle {
    ignore_changes = [
      create_option
    ]
  }
}


resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_attachment" {
  for_each = { for data_disk in var.additional_disks : data_disk.lun => data_disk }

  managed_disk_id    = azurerm_managed_disk.vm_disks[each.value.lun].id
  virtual_machine_id = var.virtual_machine_id

  lun     = each.value.lun
  caching = try(each.value.caching, "ReadOnly")

  depends_on = [
    azurerm_managed_disk.vm_disks
  ]
}
