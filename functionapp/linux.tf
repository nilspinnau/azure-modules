

resource "azurerm_linux_function_app" "default" {
  count = var.os_type != "Windows" ? 1 : 0

  name                = "func-${random_string.default.result}${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.service_plan_id

  identity {
    type = "SystemAssigned"
  }

  storage_uses_managed_identity = true
  app_settings                  = var.app_settings

  https_only                    = true
  public_network_access_enabled = var.public_network_access_enabled
  enabled                       = true

  webdeploy_publish_basic_authentication_enabled = var.webdeploy_publish_basic_authentication_enabled
  ftp_publish_basic_authentication_enabled       = var.ftp_publish_basic_authentication_enabled

  site_config {
    always_on           = var.site_config.always_on
    ftps_state          = var.site_config.ftps_state
    use_32_bit_worker   = false
    minimum_tls_version = var.site_config.min_tls_version
    linux_fx_version    = var.site_config.linux_fx_version
    http2_enabled       = var.site_config.http2_enabled
    app_command_line    = var.site_config.app_command_line
    application_stack {
      powershell_core_version = var.site_config.application_stack.powershell_core_version
      dotnet_version          = var.site_config.application_stack.dotnet_version
      node_version            = var.site_config.application_stack.node_version
      python_version          = var.site_config.application_stack.python_version
      java_version            = var.site_config.application_stack.java_version
    }
    container_registry_use_managed_identity = true
    application_insights_connection_string  = azurerm_application_insights.default.connection_string
    application_insights_key                = azurerm_application_insights.default.instrumentation_key
  }

  dynamic "auth_settings_v2" {
    for_each = var.auth_settings_v2.auth_enabled == true ? [var.auth_settings_v2] : []
    content {
      auth_enabled           = var.auth_settings_v2.auth_enabled
      require_authentication = var.auth_settings_v2.require_authentication
      require_https          = var.auth_settings_v2.require_https

      login {}

      dynamic "active_directory_v2" {
        for_each = var.auth_settings_v2.active_directory != {} ? [var.auth_settings_v2.active_directory] : []
        content {
          # Add any specific settings for active directory here if needed
          client_id            = active_directory_v2.value.client_id
          tenant_auth_endpoint = active_directory_v2.value.tenant_auth_endpoint
        }
      }

      dynamic "google_v2" {
        for_each = var.auth_settings_v2.google != {} ? [var.auth_settings_v2.google] : []
        content {
          # Add any specific settings for Google authentication here if needed
          client_id                  = google_v2.value.client_id
          client_secret_setting_name = google_v2.value.client_secret_setting_name
        }
      }

      dynamic "microsoft_v2" {
        for_each = var.auth_settings_v2.microsoft != {} ? [var.auth_settings_v2.microsoft] : []
        content {
          # Add any specific settings for Microsoft authentication here if needed
          client_id                  = microsoft_v2.value.client_id
          client_secret_setting_name = microsoft_v2.value.client_secret_setting_name
        }
      }

      dynamic "facebook_v2" {
        for_each = var.auth_settings_v2.facebook != {} ? [var.auth_settings_v2.facebook] : []
        content {
          # Add any specific settings for Facebook authentication here if needed
          app_id                  = facebook_v2.value.app_id
          app_secret_setting_name = facebook_v2.value.app_secret_setting_name
        }
      }
    }
  }

  storage_account_name = var.storage_account.name

  virtual_network_subnet_id = var.subnet_id
}
