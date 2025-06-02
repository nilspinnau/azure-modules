
# we have to wait for the disks to be assigned so that we can apply azure disk encryption
resource "time_sleep" "wait_vm_creation" {
  create_duration = "20s"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

locals {
  asg_assignments = toset(flatten([
    for nic in var.network_interface : [
      for ipc in nic.ip_configuration : [
        for id in ipc.application_security_group_ids : {
          network_interface_id    = azurerm_network_interface.default[nic.key].id
          backend_address_pool_id = id
          ip_configuration_name   = ipc.key
      }]
    ]
  ]))
}

resource "azurerm_network_interface_application_security_group_association" "default" {
  for_each = local.asg_assignments

  network_interface_id          = each.value.network_interface_id
  application_security_group_id = each.value.application_security_group_id
}


resource "azurerm_network_interface" "default" {
  for_each = var.network_interface

  name                = "nic-${each.key}-${var.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  accelerated_networking_enabled = each.value.accelerated_networking_enabled
  ip_forwarding_enabled          = false
  dns_servers                    = []

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration
    content {
      name                          = ip_configuration.key
      subnet_id                     = ip_configuration.value.subnet_id
      primary                       = ip_configuration.value.primary
      private_ip_address_version    = ip_configuration.value.private_ip_address_version
      private_ip_address_allocation = ip_configuration.value.private_ip_address != null ? "Static" : "Dynamic"
      private_ip_address            = ip_configuration.value.private_ip_address
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}


resource "azurerm_virtual_machine_automanage_configuration_assignment" "windows" {
  for_each = {
    for k, vm in azurerm_windows_virtual_machine.win_vm : k => vm
    if var.automanage.enabled == true
  }

  virtual_machine_id = each.value.id
  # this is still so buggy
  configuration_id = var.automanage.configuration_id

  depends_on = [
    time_sleep.wait_vm_creation,
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

resource "azurerm_virtual_machine_extension" "perfdiag" {
  count = try(var.monitoring.config.performance_diagnostics == true, false) && var.scale_set.enabled == false ? 1 : 0

  name                       = "AzurePerformanceDiagnostics"
  publisher                  = "Microsoft.Azure.Performance.Diagnostics"
  type                       = "AzurePerformanceDiagnostics"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  virtual_machine_id         = local.vm.id
  type_handler_version       = "1.0"

  settings = <<SETTINGS
  {
    "storageAccountName": "${var.monitoring.config.storage_account.name}",
    "performanceScenario": "basic",
    "enableContinuousDiagnostics": "True",
    "traceDurationInSeconds": "300",
    "perfCounterTrace": "p",
    "networkTrace": "n",
    "xperfTrace": "x",
    "storPortTrace": "s",
    "requestTimeUtc":  "${time_static.current.rfc3339}",
    "resourceId": "${local.vm.id}"
  }
  SETTINGS
  protected_settings = jsonencode({
    storageAccountKey = var.monitoring.config.storage_account.key
  })

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]

  tags = var.tags
}

# Any extension
resource "azurerm_virtual_machine_extension" "vm_extensions" {
  for_each = {
    for ext in local.extensions : ext.name => ext
    if var.scale_set.enabled == false
  }

  name                       = each.value.name
  virtual_machine_id         = local.vm.id
  publisher                  = each.value.publisher
  type                       = each.value.type
  type_handler_version       = each.value.version
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = try(each.value.automatic_upgrade_enabled, null)

  settings           = try(each.value.settings, null)
  protected_settings = try(each.value.protected_settings, null)

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm,
    time_sleep.configuration_apply
  ]

  tags = var.tags

  lifecycle {
    ignore_changes = [
      type_handler_version
    ]
  }
}


# we have to wait for the disks to be assigned so that we can apply azure disk encryption
resource "time_sleep" "configuration_apply" {
  count           = var.disk_encryption.type == "ade" ? 1 : 0
  create_duration = "5m"

  depends_on = [
    azurerm_policy_virtual_machine_configuration_assignment.default
  ]
}

# resource "azurerm_virtual_machine_extension" "disk_formatter" {
#   for_each = {
#     for k, vm in local.vm_ids : k => vm
#     if local.is_windows
#   }

#   name                 = "diskformatter"
#   virtual_machine_id   = each.value
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"
#   # Invoke-Command -ScriptBlock { $disks = @( Get-Disk | Where-Object PartitionStyle -eq "RAW" ); for ($i = 0; $i -lt $disks.Count; $i++) { $disknum = $disks[$i].Number; $volume = Get-Disk $disknum | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize; Format-Volume -DriveLetter $volume.Driveletter -FileSystem ReFS -NewFileSystemLabel "Data $($disknum.ToString().PadLeft(2, "0"))" -Confirm:$false } } 
#   protected_settings = <<-PROTECTED_SETTINGS
#   {
#     "commandToExecute": "powershell -EncodedCommand \"SQBuAHYAbwBrAGUALQBDAG8AbQBtAGEAbgBkACAALQBTAGMAcgBpAHAAdABCAGwAbwBjAGsAIAB7ACAAJABkAGkAcwBrAHMAIAA9ACAAQAAoACAARwBlAHQALQBEAGkAcwBrACAAfAAgAFcAaABlAHIAZQAtAE8AYgBqAGUAYwB0ACAAUABhAHIAdABpAHQAaQBvAG4AUwB0AHkAbABlACAALQBlAHEAIAAiAFIAQQBXACIAIAApADsAIABmAG8AcgAgACgAJABpACAAPQAgADAAOwAgACQAaQAgAC0AbAB0ACAAJABkAGkAcwBrAHMALgBDAG8AdQBuAHQAOwAgACQAaQArACsAKQAgAHsAIAAkAGQAaQBzAGsAbgB1AG0AIAA9ACAAJABkAGkAcwBrAHMAWwAkAGkAXQAuAE4AdQBtAGIAZQByADsAIAAkAHYAbwBsAHUAbQBlACAAPQAgAEcAZQB0AC0ARABpAHMAawAgACQAZABpAHMAawBuAHUAbQAgAHwAIABJAG4AaQB0AGkAYQBsAGkAegBlAC0ARABpAHMAawAgAC0AUABhAHIAdABpAHQAaQBvAG4AUwB0AHkAbABlACAARwBQAFQAIAAtAFAAYQBzAHMAVABoAHIAdQAgAHwAIABOAGUAdwAtAFAAYQByAHQAaQB0AGkAbwBuACAALQBBAHMAcwBpAGcAbgBEAHIAaQB2AGUATABlAHQAdABlAHIAIAAtAFUAcwBlAE0AYQB4AGkAbQB1AG0AUwBpAHoAZQA7ACAARgBvAHIAbQBhAHQALQBWAG8AbAB1AG0AZQAgAC0ARAByAGkAdgBlAEwAZQB0AHQAZQByACAAJAB2AG8AbAB1AG0AZQAuAEQAcgBpAHYAZQBsAGUAdAB0AGUAcgAgAC0ARgBpAGwAZQBTAHkAcwB0AGUAbQAgAFIAZQBGAFMAIAAtAE4AZQB3AEYAaQBsAGUAUwB5AHMAdABlAG0ATABhAGIAZQBsACAAIgBEAGEAdABhACAAJAAoACQAZABpAHMAawBuAHUAbQAuAFQAbwBTAHQAcgBpAG4AZwAoACkALgBQAGEAZABMAGUAZgB0ACgAMgAsACAAIgAwACIAKQApACIAIAAtAEMAbwBuAGYAaQByAG0AOgAkAGYAYQBsAHMAZQAgAH0AIAB9AA==\""
#   }
#   PROTECTED_SETTINGS

#   depends_on = [
#     module.windows_disks, module.linux_disks
#   ]
# }


# PATCHING
resource "azapi_resource" "update_attach" {
  count = var.patching.patch_schedule.schedule_name != "" ? 1 : 0

  # https://learn.microsoft.com/de-de/azure/templates/microsoft.maintenance/configurationassignments?pivots=deployment-language-terraform
  type      = "Microsoft.Maintenance/configurationAssignments@2023-04-01"
  name      = "default"
  parent_id = local.vm.id
  location  = var.location

  body = jsonencode({
    properties = {
      filter = {
        locations = [
          var.location
        ]
        osTypes = [
          local.is_windows ? "Windows" : "Linux"
        ]
        resourceTypes = [
          "microsoft.compute/virtualmachines",
          "microsoft.hybridcompute/machines"
        ]
        resourceGroups = [
          var.resource_group_name
        ]
      }
      maintenanceConfigurationId = var.patching.patch_schedule.schedule_id
    }
  })

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm,
    time_sleep.configuration_apply
  ]
}

resource "azurerm_virtual_machine_gallery_application_assignment" "default" {
  for_each = var.gallery_applications

  gallery_application_version_id = each.value.gallery_application_id
  virtual_machine_id             = local.is_windows ? azurerm_windows_virtual_machine.win_vm[0].id : azurerm_linux_virtual_machine.linux_vm[0].id
}