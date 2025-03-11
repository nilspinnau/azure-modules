
resource "azurerm_managed_disk" "default" {
  name                = "disk-${var.lun}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_type = try(var.disk_storage_type, "Standard_LRS")
  create_option        = try(var.create_option, "Empty")
  disk_size_gb         = var.disk_size_gb

  disk_encryption_set_id = var.disk_encryption_set_id

  zone = var.zone

  public_network_access_enabled = false
  network_access_policy         = "DenyAll" # "AllowAll"

  on_demand_bursting_enabled        = true
  optimized_frequent_attach_enabled = false
  trusted_launch_enabled            = false

  tags = var.tags

  lifecycle {
    ignore_changes = [
      create_option
    ]
  }
}


resource "azurerm_virtual_machine_data_disk_attachment" "default" {
  managed_disk_id    = azurerm_managed_disk.default.id
  virtual_machine_id = var.virtual_machine_id

  lun     = var.lun
  caching = var.caching
}
