locals {
  is_windows = strcontains(lower(var.source_image_reference.offer), "microsoft") || strcontains(lower(var.source_image_reference.offer), "windows") || strcontains(lower(var.source_image_reference.publisher), "microsoft") || strcontains(lower(var.source_image_reference.publisher), "windows")

  additional_disks = {
    for lun, disk in var.additional_disks : lun => merge(
      disk,
      {
        disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
        disk_encryption_type   = var.disk_encryption.config.type
      }
    )
  }

  network_interface_ids = [for nic in azurerm_network_interface.default : nic.id]

  vm = var.scale_set.enabled == false ? (
    local.is_windows ? try(azurerm_windows_virtual_machine.win_vm.0, null) : try(azurerm_linux_virtual_machine.linux_vm.0, null)
    ) : (
    var.scale_set.is_flexible_orchestration == true ?
    try(azurerm_orchestrated_virtual_machine_scale_set.vmss.0, null) : (
      local.is_windows ? try(azurerm_windows_virtual_machine_scale_set.win_vmss.0, null) : try(azurerm_linux_virtual_machine_scale_set.linux_vmss.0, null)
    )
  )

  disks = var.scale_set.enabled == false ? (
    local.is_windows ?
    module.windows_disks : module.linux_disks
  ) : local.additional_disks
}