resource "azurerm_monitor_workspace" "default" {
  name                = "amw-${var.resource_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_access_enabled = true
}

resource "azurerm_dashboard_grafana" "default" {
  name                = replace("grafana-aks-${var.resource_suffix}", "/[^A-Za-z0-9]+/", "")
  location            = var.location
  resource_group_name = var.resource_group_name

  grafana_major_version = 10


  identity {
    type = "SystemAssigned"
  }

  dynamic "azure_monitor_workspace_integrations" {
    for_each = var.azure_monitor_workspace_id != null ? [var.azure_monitor_workspace_id] : []
    content {
      resource_id = azure_monitor_workspace_integrations.value
    }
  }
  deterministic_outbound_ip_enabled      = true
  auto_generated_domain_name_label_scope = "TenantReuse"
  api_key_enabled                        = false

  public_network_access_enabled = true
  sku                           = "Standard"
  zone_redundancy_enabled       = false

  tags = var.tags
}