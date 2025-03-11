
# guest configuration assignment
resource "azurerm_policy_virtual_machine_configuration_assignment" "default" {
  for_each = {
    for k, v in var.machine_configurations : k => v
    if local.vm != null
  }


  name               = each.value.name
  location           = var.location
  virtual_machine_id = local.vm.id
  configuration {
    assignment_type = each.value.configuration.assignment_type
    version         = each.value.configuration.version

    content_hash = each.value.configuration.content_hash
    content_uri  = each.value.configuration.content_uri

    dynamic "parameter" {
      for_each = each.value.configuration.parameters
      content {
        name  = parameter.value.name
        value = parameter.value.value
      }
    }
  }

  depends_on = [
    module.linux_disks,
    module.windows_disks
  ]
}