data "azurerm_client_config" "current" {

}


resource "azurerm_kubernetes_cluster" "default" {
  name                = "aks-${var.resource_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  kubernetes_version  = var.kubernetes_version
  node_resource_group = var.node_resource_group_name
  sku_tier            = var.sku_tier

  dns_prefix = var.dns_prefix

  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 24

  private_cluster_enabled             = true
  private_dns_zone_id                 = var.private_dns_zone_id
  private_cluster_public_fqdn_enabled = true

  disk_encryption_set_id = var.disk_encryption_set_id

  http_application_routing_enabled = false

  automatic_upgrade_channel = "node-image"

  cost_analysis_enabled             = var.sku_tier != "Free" ? true : false
  workload_identity_enabled         = true
  local_account_disabled            = true
  azure_policy_enabled              = true
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  run_command_enabled               = true


  default_node_pool {
    name       = var.default_node.name
    node_count = var.default_node.node_count
    vm_size    = var.default_node.vm_size
    zones      = var.zones
    type       = "VirtualMachineScaleSets"

    temporary_name_for_rotation = "tmp${substr(lower(var.default_node.name), 0, 9)}"

    vnet_subnet_id = var.default_node.subnet_id

    os_sku          = var.default_node.os_sku
    os_disk_size_gb = var.default_node.os_disk_size_gb
    os_disk_type    = "Managed"

    kubelet_disk_type    = "OS"
    orchestrator_version = var.kubernetes_version

    auto_scaling_enabled = var.default_node.auto_scaling_enabled
    min_count            = var.default_node.auto_scaling_enabled ? var.default_node.min_count : null
    max_count            = var.default_node.auto_scaling_enabled ? var.default_node.max_count : null
    max_pods             = var.default_node.max_pods

    node_labels = var.default_node.node_labels

    only_critical_addons_enabled = true
    host_encryption_enabled      = var.host_encryption_enabled
    node_public_ip_enabled       = false
  }

  identity {
    type         = length(var.identity_ids) > 0 ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
  }

  dynamic "network_profile" {
    for_each = var.network_profile != null ? [var.network_profile] : []
    content {
      network_plugin      = network_profile.value.network_plugin
      network_policy      = network_profile.value.network_policy
      network_data_plane  = network_profile.value.network_data_plane
      network_plugin_mode = network_profile.value.network_plugin_mode

      pod_cidrs      = network_profile.value.pod_cidrs
      service_cidrs  = network_profile.value.service_cidrs
      dns_service_ip = network_profile.value.dns_service_ip
      ip_versions    = network_profile.value.ip_versions

      outbound_type = network_profile.value.outbound_type

      dynamic "nat_gateway_profile" {
        for_each = network_profile.value.nat_gateway_profile != null && network_profile.value.outbound_type == "userAssignedNATGateway" ? [network_profile.value.nat_gateway_profile] : []
        content {
          idle_timeout_in_minutes   = nat_gateway_profile.value.idle_timeout_in_minutes
          managed_outbound_ip_count = nat_gateway_profile.value.managed_outbound_ip_count
        }
      }
      load_balancer_sku = network_profile.value.load_balancer_sku
      dynamic "load_balancer_profile" {
        for_each = network_profile.value.load_balancer_profile != null && network_profile.value.outbound_type == "loadBalancer" ? [network_profile.value.load_balancer_profile] : []
        content {
          managed_outbound_ip_count = load_balancer_profile.value.managed_outbound_ip_count
          # effective_outbound_ips      = load_balancer_profile.value.effective_outbound_ips
          # backend_pool_type           = load_balancer_profile.value.backend_pool_type
          idle_timeout_in_minutes     = load_balancer_profile.value.idle_timeout_in_minutes
          managed_outbound_ipv6_count = load_balancer_profile.value.managed_outbound_ipv6_count
          outbound_ip_address_ids     = load_balancer_profile.value.outbound_ip_address_ids
          # outbound_ports_allocated    = load_balancer_profile.value.outbound_ports_allocated
        }
      }
    }
  }


  auto_scaler_profile {
    balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
    expander                         = var.auto_scaler_profile.expander
    max_graceful_termination_sec     = var.auto_scaler_profile.max_graceful_termination_sec
    max_node_provisioning_time       = var.auto_scaler_profile.max_node_provisioning_time
    max_unready_nodes                = var.auto_scaler_profile.max_unready_nodes
    max_unready_percentage           = var.auto_scaler_profile.max_unready_percentage
    new_pod_scale_up_delay           = var.auto_scaler_profile.new_pod_scale_up_delay
    scale_down_delay_after_add       = var.auto_scaler_profile.scale_down_delay_after_add
    scale_down_delay_after_delete    = var.auto_scaler_profile.scale_down_delay_after_delete
    scale_down_delay_after_failure   = var.auto_scaler_profile.scale_down_delay_after_failure
    scan_interval                    = var.auto_scaler_profile.scan_interval
    scale_down_unneeded              = var.auto_scaler_profile.scale_down_unneeded
    scale_down_unready               = var.auto_scaler_profile.scale_down_unready
    scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
    empty_bulk_delete_max            = var.auto_scaler_profile.empty_bulk_delete_max
    skip_nodes_with_local_storage    = var.auto_scaler_profile.skip_nodes_with_local_storage
    skip_nodes_with_system_pods      = var.auto_scaler_profile.skip_nodes_with_system_pods
  }

  dynamic "key_management_service" {
    for_each = var.key_management_service != null ? [var.key_management_service] : []
    content {
      key_vault_key_id         = key_management_service.value.key_vault_key_id
      key_vault_network_access = key_management_service.value.key_vault_network_access
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []
    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed
        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
      dynamic "not_allowed" {
        for_each = var.maintenance_window.not_allowed
        content {
          end   = not_allowed.value.end
          start = not_allowed.value.start
        }
      }
    }
  }

  storage_profile {
    blob_driver_enabled         = true
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  dynamic "linux_profile" {
    for_each = var.default_node.os_type == "Linux" ? [1] : []
    content {
      admin_username = var.admin_username
      ssh_key {
        key_data = var.admin_password
      }
    }
  }

  dynamic "windows_profile" {
    for_each = var.default_node.os_type == "Windows" ? [1] : []
    content {
      admin_username = var.admin_username
      admin_password = var.admin_password
    }
  }

  dynamic "ingress_application_gateway" {
    for_each = var.ingress_application_gateway != null ? [1] : []
    content {
      gateway_id   = var.ingress_application_gateway.gateway_id
      gateway_name = var.ingress_application_gateway.gateway_name
      subnet_id    = var.ingress_application_gateway.subnet_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider != null ? [1] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.network,
    azurerm_role_assignment.dns
  ]
  lifecycle {
    ignore_changes = [
      # Ignore nodes_count on node pool where autoscaling is on
      default_node_pool[0].node_count,
    ]
  }
}


# Additional node pools (optional)
resource "azurerm_kubernetes_cluster_node_pool" "default" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id

  vm_size = each.value.vm_size

  vnet_subnet_id = each.value.subnet_id
  pod_subnet_id  = each.value.pod_subnet_id

  zones = var.zones

  auto_scaling_enabled = each.value.auto_scaling_enabled
  node_count           = each.value.node_count
  min_count            = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count            = each.value.auto_scaling_enabled ? each.value.max_count : null
  max_pods             = each.value.max_pods


  node_labels = each.value.node_labels
  node_taints = each.value.node_taints

  priority                     = each.value.priority
  spot_max_price               = each.value.spot_max_price
  eviction_policy              = each.value.priority == "Spot" ? each.value.eviction_policy : null
  proximity_placement_group_id = each.value.proximity_placement_group_id
  ultra_ssd_enabled            = each.value.ultra_ssd_enabled

  host_encryption_enabled = var.host_encryption_enabled

  os_disk_type    = each.value.os_disk_type
  os_sku          = each.value.os_sku
  os_type         = each.value.os_type
  os_disk_size_gb = each.value.os_disk_size_gb


  workload_runtime = each.value.workload_runtime
  scale_down_mode  = each.value.scale_down_mode

  node_public_ip_enabled      = false
  temporary_name_for_rotation = "tmp${substr(lower(each.key), 0, 9)}"

  kubelet_disk_type    = "OS"
  orchestrator_version = var.kubernetes_version

  node_network_profile {
    dynamic "allowed_host_ports" {
      for_each = each.value.network_profile.allowed_host_ports
      content {
        port_start = allowed_host_ports.value.port_start
        port_end   = allowed_host_ports.value.port_end
        protocol   = allowed_host_ports.value.protocol
      }
    }
    application_security_group_ids = each.value.network_profile.application_security_group_ids
  }

  mode = "User"

  tags = var.tags
}
