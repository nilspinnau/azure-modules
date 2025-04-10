resource "azurerm_app_service_environment_v3" "default" {
  count = var.service_plan.environment != null ? 1 : 0

  name                = "ase-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  subnet_id           = var.service_plan.environment.subnet_id

  internal_load_balancing_mode = var.service_plan.environment.internal_load_balancing_mode
  zone_redundant               = var.zone_redundant

  allow_new_private_endpoint_connections = true
  remote_debugging_enabled               = true

  dynamic "cluster_setting" {
    for_each = var.service_plan.environment.cluster_settings
    content {
      name  = cluster_setting.key
      value = cluster_setting.value
    }
  }

  cluster_setting {
    name  = "DisableTls1.0"
    value = "1"
  }

  cluster_setting {
    name  = "DisableTls1.1"
    value = "1"
  }

  cluster_setting {
    name  = "InternalEncryption"
    value = "true"
  }

  tags = var.tags
}