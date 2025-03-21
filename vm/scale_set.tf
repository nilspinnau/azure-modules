resource "azurerm_orchestrated_virtual_machine_scale_set" "vmss" {
  count = var.scale_set.enabled == true && var.scale_set.is_flexible_orchestration == true ? 1 : 0

  name                         = "vmss-${var.resource_suffix}-${var.name}"
  resource_group_name          = var.resource_group_name
  extension_operations_enabled = true
  location                     = var.location

  platform_fault_domain_count = length(var.scale_set.zones) > 0 ? 1 : 2
  instances                   = 1
  sku_name                    = var.scale_set.sku_profile != null ? "Mix" : var.sku

  dynamic "sku_profile" {
    for_each = var.scale_set.sku_profile != null ? [var.scale_set.sku_profile] : []
    content {
      allocation_strategy = sku_profile.value.allocation_strategy
      vm_sizes            = sku_profile.value.vm_sizes
    }
  }

  zone_balance = var.scale_set.zone_balance
  zones        = var.scale_set.zones

  license_type = var.license_type
  priority     = "Regular"

  encryption_at_host_enabled = (var.disk_encryption.type == "host" || var.disk_encryption.type == "des+")

  # eviction_policy = "Delete" # requires spot priority

  automatic_instance_repair {
    enabled      = var.scale_set.automatic_instance_repair
    grace_period = var.scale_set.automatic_instance_repair ? "PT30M" : null
  }

  dynamic "network_interface" {
    for_each = var.network_interface
    content {
      name                          = "nic-${network_interface.key}-${var.resource_suffix}-${var.name}"
      dns_servers                   = []
      enable_accelerated_networking = network_interface.value.accelerated_networking_enabled
      enable_ip_forwarding          = false
      dynamic "ip_configuration" {
        for_each = network_interface.value.ip_configuration
        content {
          name                                         = ip_configuration.key
          primary                                      = ip_configuration.value.primary
          subnet_id                                    = ip_configuration.value.subnet_id
          version                                      = ip_configuration.value.ip_version
          application_security_group_ids               = ip_configuration.value.application_security_group_ids
          load_balancer_backend_address_pool_ids       = ip_configuration.value.load_balancer_backend_address_pool_ids
          application_gateway_backend_address_pool_ids = ip_configuration.value.application_gateway_backend_address_pool_ids
        }
      }
    }
  }

  dynamic "os_disk" {
    for_each = var.scale_set.automatic_scaling == true ? [1] : []
    content {
      caching                = "ReadWrite"
      storage_account_type   = var.disk_storage_type
      disk_size_gb           = var.os_disk_size
      disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
    }
  }

  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }

  dynamic "source_image_reference" {
    for_each = var.scale_set.automatic_scaling == true ? [1] : []
    content {
      publisher = var.source_image_reference.publisher
      offer     = var.source_image_reference.offer
      sku       = var.source_image_reference.sku
      version   = var.source_image_reference.version
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.monitoring.enabled == true ? [1] : []
    content {
      storage_account_uri = try(var.monitoring.config.storage_account_id, null)
    }
  }

  dynamic "extension" {
    for_each = {
      for k, extension in local.extensions : k => extension
      if var.scale_set.automatic_scaling == true
    }
    content {
      auto_upgrade_minor_version_enabled = true
      publisher                          = extension.value.publisher
      name                               = extension.value.name
      settings                           = try(extension.value.settings, null)
      type                               = extension.value.type
      type_handler_version               = try(extension.value.version, "1.0")
    }
  }

  dynamic "data_disk" {
    for_each = {
      for k, disk in local.additional_disks : k => disk
      if var.scale_set.automatic_scaling == true
    }
    content {
      lun                    = data_disk.value.lun
      caching                = data_disk.value.caching
      storage_account_type   = var.disk_storage_type
      create_option          = data_disk.value.create_option
      disk_size_gb           = data_disk.value.disk_size
      disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
    }
  }

  dynamic "os_profile" {
    for_each = var.scale_set.automatic_scaling == true ? [1] : []
    content {
      dynamic "windows_configuration" {
        for_each = local.is_windows == true ? [1] : []
        content {
          admin_username           = var.admin_username
          admin_password           = var.admin_password
          computer_name_prefix     = var.name
          enable_automatic_updates = var.patching.enabled
          hotpatching_enabled      = var.hotpatching_enabled
          provision_vm_agent       = true
          patch_mode               = var.patching.enabled == true ? var.patching.patch_mode : null
          patch_assessment_mode    = var.patching.enabled == true ? var.patching.patch_assessment_mode : null
          winrm_listener {
            protocol = "Http"
          }
        }
      }
      dynamic "linux_configuration" {
        for_each = local.is_windows == true ? [] : [1]
        content {
          admin_username                  = var.admin_username
          admin_password                  = var.admin_password
          disable_password_authentication = false
          provision_vm_agent              = true
          computer_name_prefix            = var.name
          patch_mode                      = var.patching.enabled == true ? var.patching.patch_mode : null
          patch_assessment_mode           = var.patching.enabled == true ? var.patching.patch_assessment_mode : null
        }
      }
    }
  }

  tags = var.tags
}

resource "azurerm_monitor_autoscale_setting" "autoscalesetting" {
  count = var.scale_set.enabled == true && var.scale_set.automatic_scaling == true ? 1 : 0

  name                = "autoscale_cpu_percentage"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = var.scale_set.is_flexible_orchestration == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : (local.is_windows == true ? azurerm_windows_virtual_machine_scale_set.win_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id)

  enabled = true

  profile {
    name = "defaultProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = var.scale_set.is_flexible_orchestration == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : (local.is_windows == true ? azurerm_windows_virtual_machine_scale_set.win_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id)
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "GreaterThan"
        threshold                = 75
        metric_namespace         = "microsoft.compute/virtualmachinescalesets"
        divide_by_instance_count = false
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = var.scale_set.is_flexible_orchestration == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : (local.is_windows == true ? azurerm_windows_virtual_machine_scale_set.win_vmss.0.id : azurerm_linux_virtual_machine_scale_set.linux_vmss.0.id)
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "LessThan"
        divide_by_instance_count = false
        threshold                = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  predictive {
    scale_mode      = "Enabled"
    look_ahead_time = "PT5M"
  }

  tags = var.tags
}