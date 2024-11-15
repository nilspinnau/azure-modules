
resource "azurerm_backup_protected_vm" "default" {
  for_each = { for item in var.backup.config.items : item.name => item if item.type == "vm" && var.backup.enabled == true }
  # count = length([ for item in var.site_recovery.config.protected_items : item if var.backup_workload.type == "vm"])

  resource_group_name = var.backup.config.vault.recovery_vault_resource_group_name
  recovery_vault_name = var.backup.config.vault.recovery_vault_name

  # source_vm_id     = var.site_recovery.config.protected_items[count.index].id # each.key
  source_vm_id     = each.value.id
  backup_policy_id = var.backup.config.vault.rsv_policy_id
}


resource "azurerm_data_protection_backup_instance_disk" "default" {
  for_each = { for item in var.backup.config.items : item.name => item if item.type == "disk" && var.backup.enabled == true }

  name                         = each.value.name
  location                     = var.backup.config.vault.location
  vault_id                     = var.backup.config.vault.backup_vault_id
  disk_id                      = each.value.id
  snapshot_resource_group_name = var.backup.config.vault.snapshot_resource_group_name
  backup_policy_id             = var.backup.config.vault.backup_policy_id

  depends_on = [
    azurerm_role_assignment.snapshot_contributor,
    azurerm_role_assignment.disk_reader
  ]
}

resource "azurerm_role_assignment" "disk_reader" {
  for_each = { for item in var.backup.config.items : item.name => item if item.type == "disk" && var.backup.enabled == true }

  scope                = each.value.id
  role_definition_name = "Disk Backup Reader"
  principal_id         = var.backup.config.vault.principal_id
}

resource "azurerm_role_assignment" "snapshot_contributor" {
  scope                = var.backup.config.vault.snapshot_resource_group_id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = var.backup.config.vault.principal_id
}