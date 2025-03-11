locals {
  is_windows = strcontains(lower(var.source_image_reference.offer), "microsoft") || strcontains(lower(var.source_image_reference.offer), "windows") || strcontains(lower(var.source_image_reference.publisher), "microsoft") || strcontains(lower(var.source_image_reference.publisher), "windows")

  vm = local.is_windows ? azurerm_windows_virtual_machine.win_vm : azurerm_linux_virtual_machine.linux_vm
}
