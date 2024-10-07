

resource "azurerm_public_ip" "pip" {
  for_each = {
    for ipconfig in var.frontend_ip_configurations : ipconfig.name => ipconfig
    if ipconfig.is_public == true
  }

  name                = "pip-agw-${var.name}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  sku      = "Standard"
  sku_tier = "Regional"

  ip_version = each.value.ip_version

  domain_name_label = each.value.domain_name

  allocation_method = "Static"
  # can either be zone redundant, zonal or not
  zones = length(var.zones) > 1 ? ["1", "2", "3"] : var.zones

  tags = var.tags
}


resource "azurerm_application_gateway" "default" {
  name                = "agw-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  zones = var.zones

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = try(var.sku.capacity, 1)
  }

  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration != {} ? [var.autoscale_configuration] : []
    content {
      min_capacity = 1 # autoscale_configuration.value.min_capacity
      max_capacity = autoscale_configuration.value.max_capacity
    }
  }

  gateway_ip_configuration {
    name      = "agw-configuration"
    subnet_id = var.subnet_id
  }

  firewall_policy_id = var.waf_configuration.enabled == true ? azurerm_web_application_firewall_policy.default.0.id : null

  dynamic "frontend_ip_configuration" {
    for_each = { for ipconfig in var.frontend_ip_configurations : ipconfig.name => ipconfig }
    content {
      name = "default" # frontend_ip_configuration.value.name
      # TODO check the first possible private ip to assign
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address            = frontend_ip_configuration.value.is_public == true ? null : frontend_ip_configuration.value.private_ip_address_allocation.private_ip_address
      subnet_id                     = frontend_ip_configuration.value.is_public == true ? null : frontend_ip_configuration.value.private_ip_address_allocation.subnet_id
      public_ip_address_id          = frontend_ip_configuration.value.is_public == true ? azurerm_public_ip.pip[frontend_ip_configuration.key].id : null
    }
  }

  dynamic "backend_address_pool" {
    for_each = var.backend_address_pools
    content {
      name = "default" # backend_address_pool.value
    }
  }

  frontend_port {
    name = "80"
    port = 80
  }

  frontend_port {
    name = "443"
    port = 443
  }

  dynamic "identity" {
    for_each = var.user_assigned_identity.enabled == true ? [var.user_assigned_identity] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = identity.value.config.create == true ? [azurerm_user_assigned_identity.uid.0.id] : [identity.value.config.id]
    }
  }

  dynamic "ssl_certificate" {
    for_each = var.ssl_certificates
    content {
      name                = "default" # ssl_certificate.value.name
      data                = try(ssl_certificate.value.data, null)
      password            = try(ssl_certificate.value.password, null)
      key_vault_secret_id = try(ssl_certificate.value.key_vault_secret_id, null)
    }
  }

  dynamic "http_listener" {
    for_each = var.http_listeners
    content {
      name                           = "default" # http_listener.value.name
      frontend_ip_configuration_name = "default" # http_listener.value.name
      frontend_port_name             = http_listener.value.port
      protocol                       = http_listener.value.protocol
      host_name                      = try(http_listener.value.host_name, null)
      ssl_certificate_name           = try(http_listener.value.ssl_certificate_name, null)
    }
  }

  dynamic "probe" {
    for_each = var.probes
    content {
      name                                      = "default" # probe.value.name
      host                                      = try(probe.value.host, null)
      protocol                                  = probe.value.protocol
      path                                      = probe.value.path
      interval                                  = probe.value.interval
      timeout                                   = probe.value.timeout
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      pick_host_name_from_backend_http_settings = false
    }
  }

  dynamic "backend_http_settings" {
    for_each = var.backend_http_settings
    content {
      cookie_based_affinity               = "Disabled"
      name                                = "default" # backend_http_settings.value.name
      port                                = backend_http_settings.value.port
      protocol                            = backend_http_settings.value.protocol
      request_timeout                     = backend_http_settings.value.request_timeout
      pick_host_name_from_backend_address = false
      host_name                           = try(backend_http_settings.value.host_name, null)
      probe_name                          = try(backend_http_settings.value.probe_name, null)
    }
  }

  dynamic "request_routing_rule" {
    for_each = var.request_routing_rules
    content {
      name                       = "default" # request_routing_rule.value.name
      rule_type                  = "Basic"
      priority                   = 1
      http_listener_name         = request_routing_rule.value.http_listener_name
      backend_address_pool_name  = "default" # request_routing_rule.value.backend_address_pool_name
      backend_http_settings_name = "default" # request_routing_rule.value.backend_http_settings_name
    }
  }

  tags = var.tags
}

resource "azurerm_web_application_firewall_policy" "default" {
  count = var.waf_configuration.enabled == true ? 1 : 0

  name                = "wafpolicy-${var.resource_postfix}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  custom_rules {
    name      = "denymypublicip"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["79.196.199.228"]
    }

    action = "Allow"
  }

  custom_rules {
    name      = "denygermany"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "GeoMatch"
      negation_condition = false
      match_values       = ["DE"]
    }

    action = "Allow"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }
}