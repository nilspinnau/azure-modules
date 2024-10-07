
resource "azurerm_backup_protected_vm" "default" {
  for_each = { for k, item in var.backup_workloads : k => item if item.type == "vm" }
  # count = length([ for item in var.site_recovery.config.protected_items : item if var.backup_workload.type == "vm"])

  resource_group_name = each.value.resource_group_name
  recovery_vault_name = basename(each.value.vault_id)

  # source_vm_id     = var.site_recovery.config.protected_items[count.index].id # each.key
  source_vm_id     = each.value.id
  backup_policy_id = each.value.policy_id
}


resource "azurerm_data_protection_backup_instance_disk" "default" {
  for_each = { for k, item in var.backup_workloads : k => item if item.type == "disk" }

  name                         = each.value.name
  location                     = each.value.location
  vault_id                     = each.value.vault_id
  disk_id                      = each.value.id
  snapshot_resource_group_name = each.value.resource_group_name
  backup_policy_id             = each.value.policy_id

  depends_on = [
    azurerm_role_assignment.snapshot_contributor,
    azurerm_role_assignment.disk_reader
  ]
}


data "azurerm_resource_group" "snapshot_rg" {
  for_each = { for item in local.unique_rg_principal_pairs : item.resource_group_name => item if item.type == "disk" }

  name = each.value.resource_group_name
}
 
resource "azurerm_role_assignment" "disk_reader" {
  for_each = { for k, item in var.backup_workloads : k => item if item.type == "disk" }

  scope                = each.value.id
  role_definition_name = "Disk Backup Reader"
  principal_id         = each.value.principal_id
}

locals {

  # https://stackoverflow.com/questions/70925994/terraform-remove-duplicates-from-map-based-on-value
  unique_rg_principal_pairs = values(
    zipmap(
      [for m in var.backup_workloads : join(":", [m.resource_group_name, m.principal_id])],
      var.backup_workloads
    )
  )
}

resource "azurerm_role_assignment" "snapshot_contributor" {
  for_each = { for item in local.unique_rg_principal_pairs : item.resource_group_name => item if item.type == "disk" }

  scope                = data.azurerm_resource_group.snapshot_rg[each.key].id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = each.value.principal_id
}