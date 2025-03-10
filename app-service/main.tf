
resource "azurerm_service_plan" "default" {
  name                = "asp-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.service_plan.os_type
  sku_name            = var.service_plan.sku

  app_service_environment_id   = var.service_plan.environment != null ? azurerm_app_service_environment_v3.default.0.id : null
  maximum_elastic_worker_count = var.service_plan.maximum_elastic_worker_count
  worker_count                 = var.service_plan.worker_count

  zone_balancing_enabled          = var.zone_redundant
  per_site_scaling_enabled        = true
  premium_plan_auto_scale_enabled = true
}

