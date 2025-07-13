

locals {
  function_app = var.os_type == "Windows" ? azurerm_windows_function_app.default.0 : azurerm_linux_function_app.default.0
}

output "id" {
  value = local.function_app.id
}

output "name" {
  value = local.function_app.name
}

output "location" {
  value = local.function_app.location
}

output "resource_group_name" {
  value = local.function_app.resource_group_name
}
