output "service_plan" {
  value = {
    name                = azurerm_service_plan.default.name
    id                  = azurerm_service_plan.default.id
    location            = azurerm_service_plan.default.location
    resource_group_name = azurerm_service_plan.default.resource_group_name
  }
}

output "app_service_environment" {
  value = var.service_plan.environment != null ? {
    name                = azurerm_app_service_environment_v3.default[0].name
    id                  = azurerm_app_service_environment_v3.default[0].id
    subnet_id           = azurerm_app_service_environment_v3.default[0].subnet_id
    resource_group_name = azurerm_app_service_environment_v3.default[0].resource_group_name
  } : null
}