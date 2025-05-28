
# guest configuration assignment
resource "azurerm_policy_virtual_machine_configuration_assignment" "default" {
  for_each = {
    for k, v in var.machine_configurations : k => v
    if var.scale_set.enabled == false
  }


  name               = each.key
  location           = var.location
  virtual_machine_id = local.vm.id
  configuration {
    assignment_type = each.value.assignment_type
    version         = each.value.version

    content_hash = each.value.content_hash
    content_uri  = each.value.content_uri

    dynamic "parameter" {
      for_each = each.value.parameters
      content {
        name  = parameter.key
        value = parameter.value
      }
    }
  }

  depends_on = [
    module.linux_disks,
    module.windows_disks
  ]
}