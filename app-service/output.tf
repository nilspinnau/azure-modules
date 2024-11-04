output "app_service_plan" {
  value = {
    name                = azurerm_service_plan.default.name
    id                  = azurerm_service_plan.default.id
    location            = azurerm_service_plan.default.location
    resource_group_name = azurerm_service_plan.default.resource_group_name

  }
}

output "app_service_environment" {
  value = var.service_plan.environment.enabled == true ? {
    name                = azurerm_app_service_environment_v3.default.name
    id                  = azurerm_app_service_environment_v3.default.id
    subnet_id           = azurerm_app_service_environment_v3.default.subnet_id
    resource_group_name = azurerm_app_service_environment_v3.default.resource_group_name
  } : null
}