
# we have to wait for the disks to be assigned so that we can apply azure disk encryption
resource "time_sleep" "wait_vm_creation" {
  create_duration = "20s"

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}


resource "azurerm_user_assigned_identity" "uid" {
  count = (var.user_assigned_identity.enabled == true || var.scale_set.enabled == true) && var.user_assigned_identity.config.create == true ? 1 : 0

  name                = "id-${var.server_name}-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_role_assignment" "default" {
  for_each = {
    for key, role in var.user_assigned_identity.config.roles : key => role
    if(var.user_assigned_identity.enabled == true || var.scale_set.enabled == true) && var.user_assigned_identity.config.create == true
  }

  scope                = var.resource_group_id
  role_definition_name = each.value
  principal_id         = azurerm_user_assigned_identity.uid.0.principal_id
}


resource "azurerm_application_security_group" "default" {
  count = var.enable_asg == true ? 1 : 0

  name                = "asg-${var.server_name}-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "default" {
  count = var.enable_asg == true && var.scale_set.enabled == false ? var.instance_count : 0

  network_interface_id          = azurerm_network_interface.nic[count.index].id
  application_security_group_id = azurerm_application_security_group.default.0.id
}

resource "azurerm_network_interface" "nic" {

  count = var.scale_set.enabled == false ? var.instance_count : 0

  name                = "nic-${format("%s%02d", var.server_name, count.index)}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  accelerated_networking_enabled = var.enable_accelerated_networking

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    primary                       = true
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"
  }

  dynamic "ip_configuration" {
    for_each = range(var.additional_ips)
    content {
      name                          = "internal_${count.index}"
      subnet_id                     = var.subnet_id
      primary                       = false
      private_ip_address_version    = "IPv4"
      private_ip_address_allocation = "Dynamic"
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}


# check if makes sense
# resource "azurerm_network_interface_application_security_group_association" "example" {
#   network_interface_id          = azurerm_network_interface.nic.id
#   application_security_group_id = azurerm_application_security_group.asg.id
# }


resource "azurerm_availability_set" "aset" {

  count = var.enable_availability_set && var.scale_set.enabled == false ? 1 : 0

  name                = "aset-${var.server_name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  platform_fault_domain_count  = 3
  platform_update_domain_count = 3
  managed                      = true

  tags = var.tags
}


# # automanage
resource "azapi_resource" "automanage_configuration_assignment" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if var.automanage.enabled == true
  }

  type      = "Microsoft.Automanage/configurationProfileAssignments@2022-05-04"
  name      = "default"
  parent_id = each.value
  body = jsonencode({
    properties = {
      "configurationProfile" : var.automanage.config.configuration_id
    }
  })

  depends_on = [
    time_sleep.wait_vm_creation,
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]
}

# resource "azurerm_virtual_machine_automanage_configuration_assignment" "windows" {
#   for_each = {
#     for k, vm in azurerm_windows_virtual_machine.win_vm : k => vm
#     if var.automanage.enabled == true
#   }

#   virtual_machine_id = each.value.id
#   # this is still so buggy
#   configuration_id = var.automanage.config.configuration_id

#   depends_on = [azurerm_windows_virtual_machine.win_vm, azurerm_linux_virtual_machine.linux_vm]
# }

# resource "azurerm_virtual_machine_automanage_configuration_assignment" "linux" {
#   for_each = {
#     for k, vm in azurerm_linux_virtual_machine.linux_vm : k => vm
#     if var.automanage.enabled == true
#   }

#   virtual_machine_id = each.value.id
#   configuration_id   = var.automanage.config.configuration_id
# }

###################
# VM extensions, recommended to be deployed and configured by azure policy

locals {

  # distinct(compact([null, {test="test"}, {hallo="here"}]))

  extensions = concat([for el in var.automanage.enabled == false ? [
    {
      name                       = "DependencyAgent"
      publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
      type                       = local.is_windows == true ? "DependencyAgentWindows" : "DependencyAgentLinux"
      version                    = "9.10"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
      settings = jsonencode({
        enableAMA = true
        }
      )
    },
    local.is_windows == true ? {
      name                       = local.is_windows == true ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
      publisher                  = "Microsoft.Azure.ChangeTrackingAndInventory"
      type                       = local.is_windows == true ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
      version                    = "2.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
      settings = jsonencode({
        enableAMA = true
        }
      )
    } : null,
    {
      name                       = local.is_windows == true ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
      publisher                  = "Microsoft.Azure.Monitor"
      type                       = local.is_windows == true ? "AzureMonitorWindowsAgent" : "AzureMonitorLinuxAgent"
      version                    = "1.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
    },
    {

      name                       = "AzureNetworkWatcherExtension"
      publisher                  = "Microsoft.Azure.NetworkWatcher"
      type                       = local.is_windows == true ? "NetworkWatcherAgentWindows" : "NetworkWatcherAgentLinux"
      version                    = "1.4"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
    },
    {
      name                       = local.is_windows == true ? "AzurePolicyforWindows" : "AzurePolicyforLinux"
      publisher                  = "Microsoft.GuestConfiguration"
      type                       = local.is_windows == true ? "ConfigurationforWindows" : "ConfigurationForLinux"
      version                    = "1.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
    },
    local.is_windows == true ? {
      name                       = "IaaSAntimalware"
      publisher                  = "Microsoft.Azure.Security"
      type                       = "IaaSAntimalware"
      version                    = "1.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = false
      settings                   = <<SETTINGS
      {
        "AntimalwareEnabled": true,
        "RealtimeProtectionEnabled": true,
        "ScheduledScanSettings": {
          "isEnabled": true,
          "day": 0,
          "time": 120,
          "scanType": "Quick"
        },
        "SignatureUpdates": {
          "FileSharesSources": "",
          "FallbackOrder": "",
          "ScheduleDay": 0,
          "UpdateInterval": 0
        },
        "CloudProtection": true
      }
      SETTINGS
    } : null,
    {
      name                       = "HealthExtension"
      publisher                  = "Microsoft.ManagedServices"
      type                       = local.is_windows == true ? "ApplicationHealthWindows" : "ApplicationHealthLinux"
      version                    = "1.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
      settings                   = <<SETTINGS
      {
        "protocol": "${local.is_windows == true ? "Tcp" : "tcp"}",
        "port": ${local.is_windows == true ? 3389 : 22},
        "requestPath": "",
        "intervalInSeconds": 5,
        "numberOfProbes": 1
      }
      SETTINGS
    }
  ] : [] : el if el != null], var.extensions)
}

locals {
  wadlogs          = "<WadCfg> <DiagnosticMonitorConfiguration overallQuotaInMB=\"4096\" xmlns=\"http://schemas.microsoft.com/ServiceHosting/2010/10/DiagnosticsConfiguration\"> <DiagnosticInfrastructureLogs scheduledTransferLogLevelFilter=\"Error\"/> <WindowsEventLog scheduledTransferPeriod=\"PT1M\" > <DataSource name=\"Application!*[System[(Level = 1 or Level = 2)]]\" /> <DataSource name=\"Security!*[System[(Level = 1 or Level = 2)]]\" /> <DataSource name=\"System!*[System[(Level = 1 or Level = 2)]]\" /></WindowsEventLog>"
  wadperfcounters1 = "<PerformanceCounters scheduledTransferPeriod=\"PT1M\"><PerformanceCounterConfiguration counterSpecifier=\"\\Processor(_Total)\\% Processor Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"CPU utilization\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Processor(_Total)\\% Privileged Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"CPU privileged time\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Processor(_Total)\\% User Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"CPU user time\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Processor Information(_Total)\\Processor Frequency\" sampleRate=\"PT15S\" unit=\"Count\"><annotation displayName=\"CPU frequency\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\System\\Processes\" sampleRate=\"PT15S\" unit=\"Count\"><annotation displayName=\"Processes\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Process(_Total)\\Thread Count\" sampleRate=\"PT15S\" unit=\"Count\"><annotation displayName=\"Threads\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Process(_Total)\\Handle Count\" sampleRate=\"PT15S\" unit=\"Count\"><annotation displayName=\"Handles\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Memory\\% Committed Bytes In Use\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"Memory usage\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Memory\\Available Bytes\" sampleRate=\"PT15S\" unit=\"Bytes\"><annotation displayName=\"Memory available\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Memory\\Committed Bytes\" sampleRate=\"PT15S\" unit=\"Bytes\"><annotation displayName=\"Memory committed\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\Memory\\Commit Limit\" sampleRate=\"PT15S\" unit=\"Bytes\"><annotation displayName=\"Memory commit limit\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\% Disk Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"Disk active time\" locale=\"en-us\"/></PerformanceCounterConfiguration>"
  wadperfcounters2 = "<PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\% Disk Read Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"Disk active read time\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\% Disk Write Time\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"Disk active write time\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Transfers/sec\" sampleRate=\"PT15S\" unit=\"CountPerSecond\"><annotation displayName=\"Disk operations\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Reads/sec\" sampleRate=\"PT15S\" unit=\"CountPerSecond\"><annotation displayName=\"Disk read operations\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Writes/sec\" sampleRate=\"PT15S\" unit=\"CountPerSecond\"><annotation displayName=\"Disk write operations\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Bytes/sec\" sampleRate=\"PT15S\" unit=\"BytesPerSecond\"><annotation displayName=\"Disk speed\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Read Bytes/sec\" sampleRate=\"PT15S\" unit=\"BytesPerSecond\"><annotation displayName=\"Disk read speed\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\PhysicalDisk(_Total)\\Disk Write Bytes/sec\" sampleRate=\"PT15S\" unit=\"BytesPerSecond\"><annotation displayName=\"Disk write speed\" locale=\"en-us\"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier=\"\\LogicalDisk(_Total)\\% Free Space\" sampleRate=\"PT15S\" unit=\"Percent\"><annotation displayName=\"Disk free space (percentage)\" locale=\"en-us\"/></PerformanceCounterConfiguration></PerformanceCounters>"
  wadcfgxstart     = "${local.wadlogs}${local.wadperfcounters1}${local.wadperfcounters2}<Metrics resourceId=\")"
  wadcfgxend       = "\"><MetricAggregation scheduledTransferPeriod=\"PT1H\"/><MetricAggregation scheduledTransferPeriod=\"PT1M\"/></Metrics></DiagnosticMonitorConfiguration></WadCfg>"
}

resource "time_static" "current" {
}

resource "azurerm_virtual_machine_extension" "performancediagnostics" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if try(var.monitoring.config.performance_diagnostics == true, false)
  }

  name                       = "AzurePerformanceDiagnostics"
  publisher                  = "Microsoft.Azure.Performance.Diagnostics"
  type                       = "AzurePerformanceDiagnostics"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  virtual_machine_id         = each.value
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
    "resourceId": "${each.value}"
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


resource "azurerm_virtual_machine_extension" "vmdiagnostics" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if try(var.monitoring.config.vm_diagnostics == true, false)
  }

  name                       = "Microsoft.Insights.VMDiagnosticsSettings"
  virtual_machine_id         = each.value
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "IaaSDiagnostics"
  type_handler_version       = "1.5"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false

  settings = jsonencode(
    {
      WadCfg         = jsondecode(templatefile("${path.module}/resources/wadcfg.tpl", { workspace_resource_id = var.monitoring.config.workspace.resource_id }))
      StorageAccount = var.monitoring.config.storage_account.name
    }
  )
  protected_settings = jsonencode({
    storageAccountName     = var.monitoring.config.storage_account.name
    storageAccountKey      = var.monitoring.config.storage_account.key
    storageAccountEndPoint = "https://core.windows.net"
    StorageType            = "Table"
  })

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]

  tags = var.tags
}

# Any extension
resource "azurerm_virtual_machine_extension" "vm_extensions" {

  count = length(local.vm_ids) * length(local.extensions)

  name                       = local.extensions[count.index % length(local.extensions)].name
  virtual_machine_id         = local.vm_ids[count.index % length(local.vm_ids)]
  publisher                  = local.extensions[count.index % length(local.extensions)].publisher
  type                       = local.extensions[count.index % length(local.extensions)].type
  type_handler_version       = local.extensions[count.index % length(local.extensions)].version
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = try(local.extensions[count.index % length(local.extensions)].automatic_upgrade_enabled, null)

  settings           = try(local.extensions[count.index % length(local.extensions)].settings, null)
  protected_settings = try(local.extensions[count.index % length(local.extensions)].protected_settings, null)


  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm
  ]

  tags = var.tags
}


# we have to wait for the disks to be assigned so that we can apply azure disk encryption
resource "time_sleep" "configuration_apply" {
  count           = var.disk_encryption.enabled == true && var.disk_encryption.config.type == "ade" ? 1 : 0
  create_duration = "5m"

  depends_on = [
    azurerm_policy_virtual_machine_configuration_assignment.default
  ]
}

resource "azurerm_virtual_machine_extension" "azure_disk_encryption" {
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if var.disk_encryption.enabled == true && var.disk_encryption.config.type == "ade"
  }

  name                       = "AzureDiskEncryption"
  virtual_machine_id         = each.value
  publisher                  = "Microsoft.Azure.Security"
  type                       = local.is_windows == true ? "AzureDiskEncryption" : "AzureDiskEncryption"
  type_handler_version       = "2.2"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  settings                   = <<SETTINGS
  {
    "EncryptionOperation": "EnableEncryption",
    "KeyEncryptionAlgorithm": "RSA-OAEP-256",
    "KeyVaultURL": "${var.disk_encryption.config.vault_uri}",
    "KeyVaultResourceId": "${var.disk_encryption.config.vault_id}",
    "VolumeType": "All"
  }
  SETTINGS

  depends_on = [
    azurerm_windows_virtual_machine.win_vm,
    azurerm_linux_virtual_machine.linux_vm,
    time_sleep.configuration_apply
  ]

  tags = var.tags
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
  for_each = {
    for k, vm in local.vm_ids : k => vm
    if var.patching.patch_schedule.schedule_name != ""
  }

  # https://learn.microsoft.com/de-de/azure/templates/microsoft.maintenance/configurationassignments?pivots=deployment-language-terraform
  type      = "Microsoft.Maintenance/configurationAssignments@2023-04-01"
  name      = "default"
  parent_id = each.value
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
  count = length(local.vm_ids) * length(var.gallery_applications)

  gallery_application_version_id = var.gallery_applications[count.index % length(var.gallery_applications)]
  virtual_machine_id             = local.vm_ids[count.index % length(local.vm_ids)]
}