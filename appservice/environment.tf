
locals {
  # unncesary if else but just for quick understanding
  create_subnet = var.service_plan.environment.config.subnet_id != "" ? true : false
  subnet_id     = local.create_subnet ? azurerm_subnet.default.0.id : var.service_plan.environment.config.subnet_id

  split_vnet_id = split("/", var.service_plan.environment.config.virtual_network_id)
}


resource "azurerm_subnet" "default" {
  count = local.create_subnet ? 1 : 0

  name                 = "snet-${var.resource_postfix}"
  resource_group_name  = local.split_vnet_id[index(split("/", local.split_vnet_id), "Microsoft.Resource")]
  virtual_network_name = local.split_vnet_id[length(local.split_vnet_id) - 1]
  address_prefixes     = [var.service_plan.environment.config.address_prefix, ]

  private_endpoint_network_policies             = "Enabled"
  private_link_service_network_policies_enabled = "Enabled"
  default_outbound_access_enabled               = false

  delegation {
    name = "Microsoft.Web.hostingEnvironments"
    service_delegation {
      name    = "Microsoft.Web/hostingEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_app_service_environment_v3" "default" {
  name                = "ase-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  subnet_id           = local.subnet_id

  internal_load_balancing_mode = "Web, Publishing"
  zone_redundant               = var.zone_redundant

  allow_new_private_endpoint_connections = true
  remote_debugging_enabled               = true

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

  dynamic "cluster_setting" {
    for_each = var.service_plan.environment.config.cluster_settings
    content {
      name  = cluster_setting.value.name
      value = cluster_setting.value.value
    }
  }

  tags = var.tags
}