

resource "azurerm_windows_function_app" "default" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = "func-${random_string.default.result}${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  identity {
    type = "SystemAssigned"
  }

  storage_uses_managed_identity = var.storage_account.access_key != null
  app_settings                  = var.app_settings

  https_only                    = true
  public_network_access_enabled = true
  enabled                       = true

  ftp_publish_basic_authentication_enabled       = true
  webdeploy_publish_basic_authentication_enabled = false

  site_config {
    always_on           = var.site_config.always_on
    ftps_state          = var.site_config.ftps_state
    use_32_bit_worker   = false
    minimum_tls_version = var.site_config.min_tls_version
    windows_fx_version  = var.site_config.linux_fx_version
    http2_enabled       = var.site_config.http2_enabled
    app_command_line    = var.site_config.app_command_line
    application_stack {
      powershell_core_version = var.site_config.application_stack.powershell_core_version
      dotnet_version          = var.site_config.application_stack.dotnet_version
      node_version            = var.site_config.application_stack.node_version
      java_version            = var.site_config.application_stack.java_version
    }
    application_insights_connection_string = azurerm_application_insights.default.connection_string
    application_insights_key               = azurerm_application_insights.default.instrumentation_key
  }

  zip_deploy_file = var.zip_deploy_file

  storage_account_name       = var.storage_account.name
  storage_account_access_key = var.storage_account.access_key

  virtual_network_subnet_id = var.subnet_id
}