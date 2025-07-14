

resource "azurerm_role_assignment" "default" {
  scope                = var.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.function_app.identity[0].principal_id

  depends_on = [
    azurerm_windows_function_app.default,
    azurerm_linux_function_app.default
  ]
}

resource "random_string" "default" {
  special = false
  upper   = false
  numeric = false
  lower   = true
  length  = 32 - length(var.resource_suffix) - 5
}