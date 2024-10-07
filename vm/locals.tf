locals {
  is_windows = strcontains(lower(var.source_image_reference.offer), "microsoft") || strcontains(lower(var.source_image_reference.offer), "windows") || strcontains(lower(var.source_image_reference.publisher), "microsoft") || strcontains(lower(var.source_image_reference.publisher), "windows")

  vm_ids = local.is_windows == true ? [for vm in azurerm_windows_virtual_machine.win_vm : vm.id] : [for vm in azurerm_linux_virtual_machine.linux_vm : vm.id]
}
