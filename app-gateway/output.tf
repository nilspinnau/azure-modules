

output "gateway_id" {
  value = try(azurerm_application_gateway.default.id, null)
}

output "backend_address_pool_ids" {
  value = try({ for pool in azurerm_application_gateway.default.backend_address_pool : pool.name => pool.id }, null)
}

output "waf_policy_id" {
  value = try(azurerm_web_application_firewall_policy.default.0.id, null)
}


output "public_ip" {
  value = {
    id : try(azurerm_public_ip.pip.0.id, null)
    domain_name = try(azurerm_public_ip.pip.0.domain_name_label, null)
  }
}