
data "azurerm_client_config" "current" {

}

resource "azurerm_private_link_service" "default" {
  count = var.loadbalancing.loadbalancer.enabled == true && var.private_link_service.enabled == true ? 1 : 0

  name                = "privatelink-${var.server_name}"
  resource_group_name = var.resource_group_name
  location            = var.az_region

  auto_approval_subscription_ids = [data.azurerm_client_config.current.subscription_id]
  enable_proxy_protocol          = false
  # we only want visibility for our own subscription id
  visibility_subscription_ids                 = [data.azurerm_client_config.current.subscription_id]
  load_balancer_frontend_ip_configuration_ids = [var.loadbalancing.loadbalancer.frontend_ip_configuration_id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = try(var.private_link_service.config.private_ip, null)
    private_ip_address_version = "IPv4"
    subnet_id                  = try(var.private_link_service.config.nat_subnet_id, null)
    primary                    = true
  }
}