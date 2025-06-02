
###################
# VM extensions, recommended to be deployed and configured by azure policy


resource "time_static" "current" {
}

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
      })
    },
    {
      name                       = local.is_windows == true ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
      publisher                  = "Microsoft.Azure.ChangeTrackingAndInventory"
      type                       = local.is_windows == true ? "ChangeTracking-Windows" : "ChangeTracking-Linux"
      version                    = "2.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
      settings = jsonencode({
        enableAMA = true
      })
    },
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
    },
    var.disk_encryption.type == "ade" ? {
      name                       = "AzureDiskEncryption"
      publisher                  = "Microsoft.Azure.Security"
      type                       = "AzureDiskEncryption"
      type_handler_version       = "2.2"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = false
      settings                   = <<SETTINGS
      {
        "EncryptionOperation": "EnableEncryption",
        "KeyEncryptionAlgorithm": "RSA-OAEP-256",
        "KeyVaultURL": "${var.disk_encryption.vault_uri}",
        "KeyVaultResourceId": "${var.disk_encryption.vault_id}",
        "VolumeType": "All"
      }
      SETTINGS
    } : null
  ] : [] : el if el != null && try(!contains(var.extensions_to_ignore, el.name), true)], [for ext in var.extensions : merge({ name = ext.name }, ext)])
}