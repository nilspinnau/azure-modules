
locals {
  machine_configuration_assignments = flatten([
    for k, vm in local.vm_ids : [
    for configuration in var.machine_configurations : merge(configuration, { virtual_machine_id = vm })]
  ])
}


resource "azurerm_policy_virtual_machine_configuration_assignment" "default" {
  for_each = {
    for k, configuration in local.machine_configuration_assignments : k => configuration
  }

  name               = each.value.name
  location           = var.location
  virtual_machine_id = each.value.virtual_machine_id
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