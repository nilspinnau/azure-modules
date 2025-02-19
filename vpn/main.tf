resource "azurerm_public_ip" "default" {
  for_each = var.ip_configuration

  name                = "pip-vpn-${each.key}-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = each.value.public_ip.allocation_method
  sku               = each.value.public_ip.sku
  sku_tier          = each.value.public_ip.sku_tier

  ddos_protection_plan_id = each.value.public_ip.ddos_protection_plan_id
  idle_timeout_in_minutes = each.value.public_ip.idle_timeout_in_minutes
  ip_version              = each.value.public_ip.ip_version
  public_ip_prefix_id     = each.value.public_ip.public_ip_prefix_id
  domain_name_label       = each.value.public_ip.domain_name_label
  reverse_fqdn            = each.value.public_ip.reverse_fqdn

  tags = var.tags
}

resource "azurerm_virtual_network_gateway" "default" {
  name                = "vpn-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = var.vpn_type

  active_active               = var.active_active
  enable_bgp                  = var.enable_bgp
  sku                         = var.sku
  private_ip_address_enabled  = var.private_ip_address_enabled
  remote_vnet_traffic_enabled = var.remote_vnet_traffic_enabled
  virtual_wan_traffic_enabled = var.virtual_wan_traffic_enabled

  generation = var.generation

  dynamic "ip_configuration" {
    for_each = var.ip_configuration
    content {
      # Mandatory attributes
      subnet_id            = ip_configuration.value.subnet_id
      public_ip_address_id = azurerm_public_ip.default[ip_configuration.key].id
      # Optional attributes
      name                          = try(ip_configuration.key, null)
      private_ip_address_allocation = try(ip_configuration.value.private_ip_address_allocation, null)
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = var.client_configuration
    content {
      # Mandatory attributes
      address_space = vpn_client_configuration.value.address_space
      # Optional attributes
      aad_tenant            = try(vpn_client_configuration.value.aad_tenant, null)
      aad_audience          = try(vpn_client_configuration.value.aad_audience, null)
      aad_issuer            = try(vpn_client_configuration.value.aad_issuer, null)
      radius_server_address = try(vpn_client_configuration.value.radius_server_address, null)
      radius_server_secret  = try(vpn_client_configuration.value.radius_server_secret, null)
      vpn_client_protocols  = try(vpn_client_configuration.value.vpn_client_protocols, null)
      vpn_auth_types        = try(vpn_client_configuration.value.vpn_auth_types, null)

      dynamic "root_certificate" {
        for_each = try(vpn_client_configuration.value.root_certificate, [])
        content {
          name             = root_certificate.value.name
          public_cert_data = root_certificate.value.public_cert_data
        }
      }

      dynamic "revoked_certificate" {
        for_each = try(vpn_client_configuration.value.revoked_certificate, [])
        content {
          name       = revoked_certificate.value.name
          thumbprint = revoked_certificate.value.thumbprint
        }
      }
    }
  }


  bgp_settings {
    asn         = try(var.bgp_settings.asn, null)
    peer_weight = try(var.bgp_settings.peer_weight, null)

    dynamic "peering_addresses" {
      for_each = try(var.bgp_settings.peering_addresses, [])
      content {
        ip_configuration_name = try(peering_addresses.value.ip_configuration_name, null)
        apipa_addresses       = try(peering_addresses.value.apipa_addresses, null)
      }
    }
  }

  dynamic "custom_route" {
    for_each = length(var.custom_route.address_prefixes) > 0 ? [var.custom_route] : []
    content {
      address_prefixes = try(var.custom_route.address_prefixes, null)
    }
  }

  tags = var.tags
}


resource "azurerm_virtual_network_gateway_connection" "direction_in" {
  for_each = var.connection

  name                = each.key
  location            = var.location
  resource_group_name = var.resource_group_name

  virtual_network_gateway_id      = azurerm_virtual_network_gateway.default.id
  peer_virtual_network_gateway_id = each.value.bi_directional_enabled == true ? each.value.peer_virtual_network_gateway_id : null
  local_network_gateway_id        = var.local_network_gateway != null ? azurerm_local_network_gateway.default.0.id : null
  type                            = each.value.type

  connection_mode = each.value.connection_mode
  enable_bgp      = each.value.enable_bgp
  shared_key      = each.value.shared_key

  tags = var.tags
}


resource "azurerm_virtual_network_gateway_connection" "direction_out" {
  for_each = { 
    for k, v in var.connection: k => v 
    if v.bi_directional_enabled
  }

  name                = "${each.key}-reverse"
  location            = each.value.remote_location
  resource_group_name = each.value.resource_group_name

  virtual_network_gateway_id      = each.value.peer_virtual_network_gateway_id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.default.id
  type                            = each.value.type


  connection_mode = each.value.connection_mode
  enable_bgp      = each.value.enable_bgp
  shared_key      = each.value.shared_key

  tags = var.tags
}


resource "azurerm_local_network_gateway" "default" {
  count = var.local_network_gateway != null ? 1 : 0

  name                = "lgw-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space   = var.local_network_gateway.address_space
  gateway_address = var.local_network_gateway.gateway_address
  gateway_fqdn    = var.local_network_gateway.gateway_fqdn

  dynamic "bgp_settings" {
    for_each = var.local_network_gateway.bgp_settings
    content {
      asn                 = bgp_settings.value.asn
      bgp_peering_address = bgp_settings.value.bgp_peering_address
      peer_weight         = bgp_settings.value.peer_weight
    }
  }

  tags = var.tags
}
