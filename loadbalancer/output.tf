
output "backend_address_pool_ids" {
  value = { for pool in azurerm_lb_backend_address_pool.lb_backend_pool : pool.name => pool.id }
}


output "frontend_ip_configuration_ids" {
  value = { for config in azurerm_lb.lb.frontend_ip_configuration : config.name => config.id }
}

output "lb_id" {
  value = try(azurerm_lb.lb.id, null)
}

output "public_ip" {
  value = {
    id : try(azurerm_public_ip.pip.0.id, null)
    domain_name = try(azurerm_public_ip.pip.0.domain_name_label, null)
  }
}