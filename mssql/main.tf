
resource "random_string" "name" {
  length  = 24 - length(var.name) - 3 - 2
  upper   = false
  special = false
}

locals {
  name          = "sql${var.name}${random_string.name.result}"
  failover_name = "sqldr${var.name}${random_string.name.result}"

  servers = {
    (local.name) = {
      name                = local.name
      resource_group_name = var.resource_group_name
      location            = var.location
    }
    (local.failover_name) = {
      name                = local.failover_name
      resource_group_name = coalesce(var.failover.resource_group_name, var.resource_group_name)
      location            = var.failover.location
    }
  }
}


resource "azurerm_mssql_server" "default" {
  for_each = local.servers

  name                = each.key
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  version             = var.sql_version

  azuread_administrator {
    login_username              = var.entra_admin.username
    object_id                   = var.entra_admin.object_id
    azuread_authentication_only = true
  }

  identity {
    type = "SystemAssigned"
  }

  minimum_tls_version                  = "1.2"
  public_network_access_enabled        = var.public_network_access_enabled
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  tags = var.tags
}

# only use with CMK
# resource "azurerm_mssql_server_transparent_data_encryption" "default" {
#   for_each = local.servers

#   server_id = azurerm_mssql_server.default[each.key].id
# }

resource "azurerm_mssql_database" "default" {
  for_each = var.databases

  name      = "sqldb-${each.key}"
  server_id = azurerm_mssql_server.default[local.name].id

  ledger_enabled = each.value.ledger_enabled

  min_capacity = each.value.min_capacity
  max_size_gb  = each.value.max_size_gb

  sku_name       = each.value.sku_name
  zone_redundant = startswith(each.value.sku_name, "BC") || startswith(each.value.sku_name, "P") ? each.value.zone_redundant : false

  threat_detection_policy {
    email_account_admins = "Enabled"
    retention_days       = 14
  }

  short_term_retention_policy {
    retention_days           = each.value.short_term_retention_policy.retention_days
    backup_interval_in_hours = each.value.short_term_retention_policy.backup_interval_in_hours
  }

  long_term_retention_policy {
    monthly_retention = each.value.long_term_retention_policy.monthly_retention
    weekly_retention  = each.value.long_term_retention_policy.weekly_retention
    yearly_retention  = each.value.long_term_retention_policy.yearly_retention
    week_of_year      = each.value.long_term_retention_policy.week_of_year
  }

  collation = each.value.collation
  # elastic_pool_id    = each.value.elastic_pool_id
  license_type = each.value.license_type

  storage_account_type = each.value.storage_account_type
  geo_backup_enabled   = each.value.geo_backup_enabled

  transparent_data_encryption_enabled = true

  # SKU is hyperscale
  read_replica_count = startswith(each.value.sku_name, "HS") ? each.value.read_replica_count : null
  # SKU is business critical or premium
  read_scale = startswith(each.value.sku_name, "BC") || startswith(each.value.sku_name, "P") ? each.value.read_scale : null

  enclave_type = each.value.enable_enclave ? "VBS" : null
  tags         = var.tags
}


# enable failover group if failover is enabled
resource "azurerm_mssql_failover_group" "default" {
  count = var.failover != null ? 1 : 0

  name      = "failover-group"
  databases = [for db in var.databases : azurerm_mssql_database.default[db.name].id if db.active_failover_enabled]

  readonly_endpoint_failover_policy_enabled = true
  partner_server {
    id = azurerm_mssql_server.default[local.failover_name].id
  }
  server_id = azurerm_mssql_server.default[local.name].id

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}