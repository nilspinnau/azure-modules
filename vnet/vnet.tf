
resource "azurerm_virtual_network" "default" {
  name                = "vnet-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  address_space = [var.address_space]

  dns_servers = var.dns_servers

  encryption {
    enforcement = "AllowUnencrypted"
  }

  tags = var.tags
}

locals {
  newbits         = [for _, subnet in var.subnets : subnet.newbit]
  subnet_prefixes = cidrsubnets(var.address_space, local.newbits...)
  subnets         = { for k, subnet in var.subnets : subnet.name => local.subnet_prefixes[k] }
}

resource "azurerm_subnet" "default" {
  for_each = { for k, subnet in var.subnets : subnet.name => subnet }

  name                = each.key
  resource_group_name = var.resource_group_name

  virtual_network_name = azurerm_virtual_network.default.name

  address_prefixes  = [local.subnets[each.key]]
  service_endpoints = each.value.service_endpoints

  dynamic "delegation" {
    for_each = try(each.value.delegation, null) != null ? [each.value.delegation] : []
    iterator = delegation
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  private_endpoint_network_policies             = each.value.private_endpoint_network_policies

  depends_on = [azurerm_virtual_network.default]
}


resource "azurerm_public_ip" "pip" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.nat_gateway == true
  }

  name                = "pip-nat-${each.value.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.nat_gateway == true
  }
  name                = "nat-${each.value.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_nat_gateway_public_ip_association" "pip" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.nat_gateway == true
  }
  nat_gateway_id       = azurerm_nat_gateway.nat[each.key].id
  public_ip_address_id = azurerm_public_ip.pip[each.key].id
}


resource "azurerm_subnet_nat_gateway_association" "association" {
  for_each = {
    for k, subnet in var.subnets : subnet.name => subnet
    if subnet.nat_gateway == true
  }
  nat_gateway_id = azurerm_nat_gateway.nat[each.key].id
  subnet_id      = azurerm_subnet.default[each.key].id
}


resource "azurerm_private_dns_zone_virtual_network_link" "dns_links" {
  for_each = var.dns_zone_links

  name = each.key

  private_dns_zone_name = each.value.private_dns_zone_name
  resource_group_name   = each.value.resource_group_name

  virtual_network_id = azurerm_virtual_network.default.id
}