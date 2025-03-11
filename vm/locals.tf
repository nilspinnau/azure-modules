locals {
  is_windows = strcontains(lower(var.source_image_reference.offer), "microsoft") || strcontains(lower(var.source_image_reference.offer), "windows") || strcontains(lower(var.source_image_reference.publisher), "microsoft") || strcontains(lower(var.source_image_reference.publisher), "windows")

  vm = local.is_windows ? try(azurerm_windows_virtual_machine.win_vm.0, null) : try(azurerm_linux_virtual_machine.linux_vm.0, null)
}
