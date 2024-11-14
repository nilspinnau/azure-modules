
resource "azurerm_public_ip" "pip" {
  for_each = {
    for ipconfig in var.frontend_ip_configurations : ipconfig.name => ipconfig
    if ipconfig.is_public == true
  }

  name                = "pip-lb-${var.name}-${each.value.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku      = "Standard"
  sku_tier = "Regional"

  ip_version = each.value.ip_version

  domain_name_label = each.value.domain_name

  allocation_method = "Static"
  # can either be zone redundant, zonal or not
  zones = length(each.value.zones) > 1 ? ["1", "2", "3"] : each.value.zones

  tags = var.tags
}

resource "azurerm_lb" "lb" {
  name                = "lb-${var.name}-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  dynamic "frontend_ip_configuration" {
    for_each = { for ipconfig in var.frontend_ip_configurations : ipconfig.name => ipconfig }
    content {
      name = frontend_ip_configuration.value.name
      # TODO check the first possible private ip to assign
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address != null ? "Static" : "Dynamic"
      private_ip_address            = frontend_ip_configuration.value.is_public == true ? null : frontend_ip_configuration.value.private_ip_address
      private_ip_address_version    = frontend_ip_configuration.value.is_public == true ? null : try(frontend_ip_configuration.value.ip_version, null)
      subnet_id                     = frontend_ip_configuration.value.is_public == true ? null : frontend_ip_configuration.value.subnet_id
      zones                         = frontend_ip_configuration.value.is_public == true ? null : try(frontend_ip_configuration.value.zones, null)
      public_ip_address_id          = frontend_ip_configuration.value.is_public == true ? azurerm_public_ip.pip[frontend_ip_configuration.key].id : null
    }
  }

  sku      = "Standard"
  sku_tier = "Regional"

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  for_each = {
    for backend_pool in var.backend_address_pools : backend_pool => backend_pool
  }

  loadbalancer_id = azurerm_lb.lb.id

  name = each.value
}


resource "azurerm_lb_probe" "health_probe" {
  for_each = {
    for probe in var.health_probes : probe.name => probe
  }

  name = each.value.name

  port = each.value.port
  # only allowed when protocol is Http or Https
  request_path        = title(lower(each.value.protocol)) != "Tcp" ? each.value.path : null
  protocol            = title(lower(each.value.protocol))
  interval_in_seconds = each.value.interval_in_seconds
  loadbalancer_id     = azurerm_lb.lb.id
  probe_threshold     = each.value.probe_threshold
  number_of_probes    = each.value.number_of_failed_probes
}


# we can do only so much with terraform, if there is nothing given then the app owner does it themselves, its not magic
resource "azurerm_lb_rule" "inbound" {
  for_each = {
    for rule in try(var.inbound_rules, []) : rule.name => rule
  }

  name = each.value.name

  backend_port  = each.value.backend_port
  frontend_port = each.value.frontend_port
  protocol      = each.value.protocol

  enable_floating_ip = each.value.enable_floating_ip
  enable_tcp_reset   = each.value.enable_tcp_reset

  idle_timeout_in_minutes = 4

  probe_id                       = try(azurerm_lb_probe.health_probe[each.value.probe_name].id, null)
  loadbalancer_id                = azurerm_lb.lb.id
  backend_address_pool_ids       = [for backend_name in each.value.backend_address_pool_names : azurerm_lb_backend_address_pool.lb_backend_pool[backend_name].id]
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name

  disable_outbound_snat = each.value.disable_outbound_snat
}


resource "azurerm_lb_nat_rule" "nat_rule" {
  for_each = {
    for rule in var.nat_rules : rule.name => rule
  }

  resource_group_name = var.resource_group_name

  name                    = each.value.name
  loadbalancer_id         = azurerm_lb.lb.id
  backend_address_pool_id = try(azurerm_lb_backend_address_pool.lb_backend_pool[each.value.backend_address_pool_name].id, null)

  protocol     = each.value.protocol
  backend_port = each.value.backend_port

  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name

  frontend_port       = try(each.value.frontend_port, null)
  frontend_port_end   = try(each.value.frontend_port_end, null)
  frontend_port_start = try(each.value.frontend_port_start, null)

  enable_floating_ip      = try(each.value.enable_floating_ip, null)
  enable_tcp_reset        = try(each.value.enable_tcp_reset, null)
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
}

# To create an outbound rule, the load balancer SKU must be standard and the frontend IP configuration must have at least one public IP address.
resource "azurerm_lb_outbound_rule" "this" {
  for_each = {
    for rule in try(var.outbound_rules, []) : rule.name => rule
  }
  name = each.value.name

  loadbalancer_id         = azurerm_lb.lb.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_pool[each.value.backend_address_pool_name].id

  protocol = each.value.protocol

  allocated_outbound_ports = each.value.number_of_allocated_outbound_ports
  enable_tcp_reset         = each.value.enable_tcp_reset
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configurations

    content {
      name = frontend_ip_configuration.value.name
    }
  }
}

resource "azurerm_lb_nat_pool" "this" {
  for_each = {
    for pool in try(var.nat_pool, []) : pool.name => pool
  }
  resource_group_name = var.resource_group_name

  name            = each.value.name
  loadbalancer_id = azurerm_lb.lb.id

  protocol     = each.value.protocol
  backend_port = each.value.backend_port

  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  frontend_port_end              = each.value.frontend_port_end
  frontend_port_start            = each.value.frontend_port_start

  floating_ip_enabled     = each.value.enable_floating_ip
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  tcp_reset_enabled       = each.value.enable_tcp_reset
}