resource "azurerm_private_link_service" "default" {
  for_each = var.private_link_service

  name                = "pl-${var.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  auto_approval_subscription_ids = each.value.auto_approval_subscription_ids
  enable_proxy_protocol          = each.value.enable_proxy_protocol
  # we only want visibility for our own subscription id
  visibility_subscription_ids                 = each.value.visibility_subscription_ids
  load_balancer_frontend_ip_configuration_ids = each.value.load_balancer_frontend_ip_configuration_ids

  dynamic "nat_ip_configuration" {
    for_each = each.value != null ? each.value.nat_ip_configuration : {}
    content {
      name                       = nat_ip_configuration.key
      private_ip_address         = nat_ip_configuration.value.private_ip
      private_ip_address_version = nat_ip_configuration.value.private_ip_address_version
      subnet_id                  = nat_ip_configuration.value.subnet_id
      primary                    = nat_ip_configuration.value.primary
    }
  }
}