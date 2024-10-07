
resource "azurerm_monitor_data_collection_rule_association" "vminsights" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if var.monitoring.enabled == true && try(var.monitoring.config.vm_insights != null, false) && var.automanage.enabled == false
  }

  name                    = "VMInsights"
  target_resource_id      = each.value
  data_collection_rule_id = var.monitoring.config.vm_insights.data_collection_rule_id
  description             = "TBD"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "changetracking" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if var.monitoring.enabled == true && try(var.monitoring.config.change_tracking != null, false) && var.automanage.enabled == false
  }

  name                    = "ChangeTracking"
  target_resource_id      = each.value
  data_collection_rule_id = var.monitoring.config.change_tracking.data_collection_rule_id
  description             = "TBD"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

