locals {
  is_windows = strcontains(lower(var.source_image_reference.offer), "microsoft") || strcontains(lower(var.source_image_reference.offer), "windows") || strcontains(lower(var.source_image_reference.publisher), "microsoft") || strcontains(lower(var.source_image_reference.publisher), "windows")

  additional_disks = {
    for lun, disk in var.additional_disks : lun => merge(
      disk,
      {
        id                     = null
        lun                    = lun
        name                   = "disk-${lun}-${var.name}-${var.resource_suffix}"
        disk_encryption_set_id = var.disk_encryption.disk_encryption_set_id
        disk_encryption_type   = var.disk_encryption.type
      }
    )
  }

  network_interface_ids = [for nic in azurerm_network_interface.default : nic.id]

  vm = var.scale_set.enabled == false ? (
    local.is_windows ? azurerm_windows_virtual_machine.win_vm.0 : azurerm_linux_virtual_machine.linux_vm.0
    ) : (
    var.scale_set.is_flexible_orchestration == true ?
    azurerm_orchestrated_virtual_machine_scale_set.vmss.0 : (
      local.is_windows ? azurerm_windows_virtual_machine_scale_set.win_vmss.0 : try(azurerm_linux_virtual_machine_scale_set.linux_vmss.0, null)
    )
  )

  disks = var.scale_set.enabled == false ? (
    local.is_windows ?
    { for lun, disk in module.windows_disks : lun => disk.disk } :
    { for lun, disk in module.linux_disks : lun => disk.disk }
  ) : local.additional_disks

  os_disk = merge(
    local.vm.os_disk[0],
    {
      # a little hacky, but otherwise this seems difficult, id cannot be inferred for scale sets
      id                   = try("${var.resource_group_id}/providers/Microsoft.Compute/disks/${local.vm.os_disk[0].name}", null)
      disk_encryption_type = var.disk_encryption.type
    }
  )
}