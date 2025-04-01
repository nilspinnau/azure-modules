
resource "azurerm_role_assignment" "example" {
  for_each = {
    for k, v in local.servers : k => v
    if(var.auditing.storage_account != null ||
    var.auditing.log_analytics != null) &&
    var.auditing.extended_auditing_policy_enabled == true
  }

  scope                = var.auditing.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_mssql_server.default[each.key].identity[0].principal_id
}


resource "azurerm_mssql_server_extended_auditing_policy" "default" {
  for_each = {
    for k, v in local.servers : k => v
    if(var.auditing.storage_account != null ||
    var.auditing.log_analytics != null) &&
    var.auditing.extended_auditing_policy_enabled == true
  }
  server_id = azurerm_mssql_server.default[each.key].id

  # https://learn.microsoft.com/en-us/azure/azure-sql/database/audit-write-storage-account-behind-vnet-firewall?view=azuresql
  # those values are null
  storage_endpoint                = var.auditing.storage_account.primary_blob_endpoint
  storage_account_subscription_id = var.auditing.storage_account.subscription_id

  retention_in_days      = 90
  log_monitoring_enabled = var.auditing.log_analytics != null ? true : false # verbosity wins
  enabled                = var.auditing.extended_auditing_policy_enabled

  depends_on = [
    azurerm_mssql_server.default
  ]
}

resource "azurerm_mssql_server_microsoft_support_auditing_policy" "default" {
  for_each = {
    for k, v in local.servers : k => v
    if(var.auditing.storage_account != null ||
    var.auditing.log_analytics != null) &&
    var.auditing.support_auditing_policy_enabled == true
  }

  server_id = azurerm_mssql_server.default[each.key].id
  # https://learn.microsoft.com/en-us/azure/azure-sql/database/audit-write-storage-account-behind-vnet-firewall?view=azuresql
  blob_storage_endpoint           = var.auditing.storage_account.primary_blob_endpoint
  storage_account_subscription_id = var.auditing.storage_account.subscription_id

  log_monitoring_enabled = var.auditing.log_analytics != null ? true : false # verbosity wins
  enabled                = var.auditing.support_auditing_policy_enabled

  depends_on = [
    azurerm_mssql_server.default,
    azurerm_mssql_server_extended_auditing_policy.default
  ]
}


# https://learn.microsoft.com/en-us/azure/azure-sql/database/audit-write-storage-account-behind-vnet-firewall?view=azuresql
resource "azurerm_mssql_server_security_alert_policy" "default" {
  for_each = {
    for k, v in local.servers : k => v
    if(var.auditing.storage_account != null ||
    var.auditing.log_analytics != null) &&
    var.auditing.security_alert_policy_enabled == true
  }

  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.default[each.key].name
  state               = var.auditing.security_alert_policy_enabled ? "Enabled" : "Disabled"

  storage_endpoint = var.auditing.storage_account.primary_blob_endpoint

  retention_days = var.auditing.log_retention_days

  disabled_alerts = var.disabled_alerts

  email_addresses      = var.users_to_email
  email_account_admins = false
}

resource "azurerm_mssql_server_vulnerability_assessment" "default" {
  for_each = {
    for k, v in local.servers : k => v
    if var.auditing.storage_account != null &&
    try(var.auditing.storage_account.vulnerability_container_path != "", false) &&
    var.auditing.security_alert_policy_enabled == true
  }

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.default.0.id
  storage_container_path          = var.auditing.storage_account.vulnerability_container_path

  recurring_scans {
    email_subscription_admins = false
    enabled                   = true
    emails                    = var.users_to_email
  }
}


# https://github.com/hashicorp/terraform-provider-azurerm/blob/main/examples/sql-azure/sql_auditing_log_analytics/main.tf
resource "azurerm_monitor_diagnostic_setting" "extaudit" {
  for_each = {
    for k, v in local.servers : k => v
    if var.extaudit_diag_logs != [] &&
    (var.auditing.log_analytics != null ||
    var.auditing.storage_account != null)
  }

  name                           = lower("ds-mssql_extended_auditing")
  target_resource_id             = "${azurerm_mssql_server.default[each.key].id}/databases/master"
  log_analytics_workspace_id     = var.auditing.log_analytics.workspace_resource_id
  log_analytics_destination_type = "Dedicated"
  storage_account_id             = try(var.auditing.storage_account.id, null)


  dynamic "enabled_log" {
    for_each = var.extaudit_diag_logs
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [
      metric,
      enabled_log
    ]
  }

  depends_on = [
    azurerm_mssql_server.default,
    azurerm_mssql_database.default
  ]
}

resource "azurerm_mssql_database_extended_auditing_policy" "example" {
  for_each               = local.servers
  database_id            = "${azurerm_mssql_server.default[each.key].id}/databases/master"
  log_monitoring_enabled = true

  depends_on = [
    azurerm_mssql_server.default,
    azurerm_mssql_database.default
  ]
}


data "azurerm_monitor_diagnostic_categories" "mssql_db_diag" {
  for_each = { for database in var.databases : database.name => database }

  resource_id = azurerm_mssql_database.default[each.value.name].id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings_db" {
  for_each = { for database in var.databases : database.name => database }

  name                           = lower("ds-${each.value.name}-${var.resource_suffix}")
  target_resource_id             = azurerm_mssql_database.default[each.value.name].id
  log_analytics_workspace_id     = var.auditing.log_analytics.workspace_resource_id
  log_analytics_destination_type = "Dedicated"
  storage_account_id             = try(var.auditing.storage_account.id, null)

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.mssql_db_diag[each.value.name].metrics
    content {
      category = metric.value
      enabled  = true
    }
  }

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.mssql_db_diag[each.value.name].log_category_types
    content {
      category = enabled_log.value
    }
  }

  depends_on = [
    azurerm_mssql_server.default,
    azurerm_mssql_database.default
  ]
}