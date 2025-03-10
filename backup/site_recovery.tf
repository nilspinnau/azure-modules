


resource "azurerm_site_recovery_fabric" "primary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name     = "fb-primary-${var.site_recovery.config.app_name}-${var.site_recovery.config.primary.location}"
  location = var.site_recovery.config.primary.location

  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)
}

resource "azurerm_site_recovery_fabric" "secondary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name     = "fb-secondary-${var.site_recovery.config.app_name}-${var.site_recovery.config.secondary.location}"
  location = var.site_recovery.config.secondary.location

  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)
}

resource "azurerm_site_recovery_protection_container" "primary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "pc-primary-${var.site_recovery.config.app_name}-${var.site_recovery.config.secondary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  recovery_fabric_name = azurerm_site_recovery_fabric.primary.0.name
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "pc-secondary-${var.site_recovery.config.app_name}-${var.site_recovery.config.primary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.0.name
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = var.site_recovery.config.replication_policy.name
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  recovery_point_retention_in_minutes                  = var.site_recovery.config.replication_policy.recovery_point_retention_in_minutes
  application_consistent_snapshot_frequency_in_minutes = var.site_recovery.config.replication_policy.application_consistent_snapshot_frequency_in_minutes
}

resource "azurerm_site_recovery_protection_container_mapping" "failover_to_secondary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "failover-${var.site_recovery.config.app_name}-to-${var.site_recovery.config.secondary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  recovery_fabric_name = azurerm_site_recovery_fabric.primary.0.name

  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.0.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.0.id

  recovery_replication_policy_id = azurerm_site_recovery_replication_policy.policy.0.id

  automatic_update {
    enabled               = try(var.site_recovery.config.secondary.automation_account_id != null, false)
    automation_account_id = var.site_recovery.config.secondary.automation_account_id
    authentication_type   = "SystemAssignedIdentity"
  }
}

resource "azurerm_site_recovery_protection_container_mapping" "failback_to_primary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "failback-${var.site_recovery.config.app_name}-to-${var.site_recovery.config.primary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.0.name

  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.secondary.0.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.primary.0.id

  recovery_replication_policy_id = azurerm_site_recovery_replication_policy.policy.0.id

  automatic_update {
    enabled               = try(var.site_recovery.config.secondary.automation_account_id != null, false)
    automation_account_id = var.site_recovery.config.primary.automation_account_id
    authentication_type   = "SystemAssignedIdentity"
  }
}

resource "azurerm_site_recovery_network_mapping" "failover_to_primary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "failover-${var.site_recovery.config.app_name}-to-${var.site_recovery.config.secondary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.0.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.0.name

  source_network_id = var.site_recovery.config.primary.virtual_network_id
  target_network_id = var.site_recovery.config.secondary.virtual_network_id
}

resource "azurerm_site_recovery_network_mapping" "failback_to_secondary" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                = "failback-${var.site_recovery.config.app_name}-to-${var.site_recovery.config.primary.location}"
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  source_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.0.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.primary.0.name

  source_network_id = var.site_recovery.config.secondary.virtual_network_id
  target_network_id = var.site_recovery.config.primary.virtual_network_id
}

data "azapi_resource_list" "primary_encryption_keys" {
  count = anytrue([for item in var.site_recovery.config.protected_items : item.os_disk.disk_encryption_type == "ade" || anytrue([for disk in item.managed_disks : disk.disk_encryption_type == "ade"])]) && var.site_recovery.enabled == true ? 1 : 0

  type                   = "Microsoft.KeyVault/vaults/secrets@2023-07-01"
  parent_id              = var.site_recovery.config.primary.key_vault_id
  response_export_values = ["value"]
}


# locals {
#   # encrypt_keys_mapped_to_vm_name = [for i in [for el in try(jsondecode(data.azapi_resource_list.primary_encryption_keys.output).value, []) : try(merge(el, { vm_name = try(el.tags["MachineName"], "") }), null)] : i if i != null]
#   # encrypt_keys_mapped_to_vm_name = { for k, i in [for el in try(jsondecode(data.azapi_resource_list.primary_encryption_keys.output).value, []) : el] : k => i if i != null }
# }

data "azurerm_key_vault_secret" "primary" {
  for_each = { for k, item in try(jsondecode(data.azapi_resource_list.primary_encryption_keys.0.output).value, []) : k => item if var.site_recovery.enabled == true }

  name         = each.value.name
  key_vault_id = var.site_recovery.config.primary.key_vault_id
}

# recreate all the keys in the respective region
resource "azurerm_key_vault_secret" "secondary" {
  for_each = { for k, item in data.azurerm_key_vault_secret.primary : k => item if var.site_recovery.enabled == true }

  name  = each.value.name
  value = each.value.value

  key_vault_id = var.site_recovery.config.secondary.key_vault_id

  tags = each.value.tags
}

resource "azurerm_site_recovery_replicated_vm" "default" {
  for_each = { for item in var.site_recovery.config.protected_items : item.name => item if var.site_recovery.enabled == true }

  name                = each.value.name
  resource_group_name = var.site_recovery.config.resource_group_name
  recovery_vault_name = basename(var.site_recovery.config.vault_id)

  source_recovery_fabric_name               = azurerm_site_recovery_fabric.primary.0.name
  source_vm_id                              = each.value.id
  source_recovery_protection_container_name = azurerm_site_recovery_protection_container.primary.0.name


  target_resource_group_id                = var.site_recovery.config.secondary.resource_group_id
  target_recovery_fabric_id               = azurerm_site_recovery_fabric.secondary.0.id
  target_recovery_protection_container_id = azurerm_site_recovery_protection_container.secondary.0.id

  recovery_replication_policy_id = azurerm_site_recovery_replication_policy.policy.0.id

  target_zone = each.value.zone

  managed_disk {
    disk_id                    = each.value.os_disk.id
    staging_storage_account_id = var.site_recovery.config.primary.staging_storage_account_id
    target_resource_group_id   = var.site_recovery.config.secondary.resource_group_id
    target_disk_type           = each.value.os_disk.storage_account_type
    target_replica_disk_type   = each.value.os_disk.storage_account_type

    target_disk_encryption_set_id = strcontains(each.value.os_disk.disk_encryption_type, "des") ? var.site_recovery.config.secondary.disk_encryption_set_id : null

    target_disk_encryption = each.value.os_disk.disk_encryption_type == "ade" ? [for encrypt_key in azurerm_key_vault_secret.secondary : {
      disk_encryption_key = [{
        secret_url = encrypt_key.id
        vault_id   = encrypt_key.key_vault_id
      }]
      key_encryption_key = []
    } if try(encrypt_key.tags["MachineName"], "") == each.value.name && strcontains(try(encrypt_key.tags["VolumeLetter"], ""), "C:")] : []
  }

  dynamic "managed_disk" {
    for_each = { for k, managed_disk in each.value.managed_disks : k => managed_disk }
    content {
      disk_id                    = managed_disk.value.id
      staging_storage_account_id = var.site_recovery.config.primary.staging_storage_account_id
      target_resource_group_id   = var.site_recovery.config.secondary.resource_group_id
      target_disk_type           = managed_disk.value.storage_account_type
      target_replica_disk_type   = managed_disk.value.storage_account_type

      target_disk_encryption_set_id = strcontains(managed_disk.value.disk_encryption_type, "des") ? var.site_recovery.config.secondary.disk_encryption_set_id : null

      target_disk_encryption = each.value.os_disk.disk_encryption_type == "ade" ? [for encrypt_key in azurerm_key_vault_secret.secondary : {
        disk_encryption_key = [{
          secret_url = encrypt_key.id
          vault_id   = encrypt_key.key_vault_id
        }]
        key_encryption_key = []
      } if try(encrypt_key.tags["MachineName"], "") == each.value.name && strcontains(try(encrypt_key.tags["VolumeLetter"], ""), managed_disk.value.letter)] : []
    }
  }

  network_interface {
    source_network_interface_id = each.value.network_interface_id
    target_subnet_name          = var.site_recovery.config.secondary.subnet_name
  }

  depends_on = [
    azurerm_site_recovery_protection_container_mapping.failover_to_secondary,
    azurerm_site_recovery_protection_container_mapping.failback_to_primary,
    azurerm_site_recovery_network_mapping.failback_to_secondary,
    azurerm_site_recovery_network_mapping.failover_to_primary,
  ]
}


resource "azurerm_site_recovery_replication_recovery_plan" "default" {
  count = var.site_recovery.enabled == true ? 1 : 0

  name                      = "default-recover-plan"
  recovery_vault_id         = var.site_recovery.config.vault_id
  source_recovery_fabric_id = azurerm_site_recovery_fabric.primary.0.id
  target_recovery_fabric_id = azurerm_site_recovery_fabric.secondary.0.id


  failover_recovery_group {
    post_action {
      name                      = "failover"
      type                      = "ManualActionDetails"
      fail_over_directions      = ["RecoveryToPrimary", "PrimaryToRecovery"]
      fail_over_types           = ["TestFailover", "PlannedFailover", "UnplannedFailover"]
      manual_action_instruction = "Do failover"
    }
  }

  shutdown_recovery_group {
  }

  boot_recovery_group {
    replicated_protected_items = [for vm in azurerm_site_recovery_replicated_vm.default : vm.id]
  }
}