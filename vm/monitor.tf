
resource "azurerm_monitor_data_collection_rule_association" "vminsights" {
  count = var.monitoring.enabled == true && try(var.monitoring.config.vm_insights != null, false) && var.automanage.enabled == false && local.vm != null ? 1 : 0

  name                    = "VMInsights"
  target_resource_id      = local.vm.id
  data_collection_rule_id = var.monitoring.config.vm_insights.data_collection_rule_id
  description             = "TBD"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "changetracking" {
  count = var.monitoring.enabled == true && try(var.monitoring.config.change_tracking != null, false) && var.automanage.enabled == false && local.vm != null ? 1 : 0

  name                    = "ChangeTracking"
  target_resource_id      = local.vm.id
  data_collection_rule_id = var.monitoring.config.change_tracking.data_collection_rule_id
  description             = "TBD"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

