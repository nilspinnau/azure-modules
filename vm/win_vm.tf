resource "azurerm_windows_virtual_machine" "win_vm" {

  count = local.is_windows == true && var.scale_set.enabled == false ? 1 : 0

  name                = var.name
  computer_name       = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  virtual_machine_scale_set_id = var.scale_set.enabled == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : null

  zone = var.zone

  allow_extension_operations        = true
  encryption_at_host_enabled        = (var.disk_encryption.type == "host" || var.disk_encryption.type == "des+")
  vm_agent_platform_updates_enabled = true


  hotpatching_enabled      = var.hotpatching_enabled
  enable_automatic_updates = var.automatic_updates_enabled

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled


  license_type       = var.license_type
  provision_vm_agent = true

  patch_mode            = var.patching.enabled == true ? var.patching.patch_mode : null
  patch_assessment_mode = var.patching.enabled == true ? var.patching.patch_assessment_mode : null
  # https://learn.microsoft.com/en-us/azure/update-manager/manage-dynamic-scoping?tabs=avms%2Cvm#add-a-dynamic-scope
  bypass_platform_safety_checks_on_user_schedule_enabled = var.patching.enabled == true && var.patching.schedule != null

  size                  = var.sku
  network_interface_ids = local.network_interface_ids

  winrm_listener {
    protocol = "Http"
  }

  dynamic "boot_diagnostics" {
    for_each = var.monitoring.enabled == true ? [1] : []
    content {
      storage_account_uri = try(var.monitoring.config.storage_account_id, null)
    }
  }

  os_disk {
    name                   = "osdisk-${var.name}-${var.resource_suffix}"
    caching                = "ReadWrite"
    storage_account_type   = var.disk_storage_type
    disk_size_gb           = var.os_disk_size
    disk_encryption_set_id = var.disk_encryption.disk_encryption_set_id
  }


  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }
  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) <= 0 ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }
  tags = var.tags
}

module "windows_disks" {
  source = "./modules/disks"

  for_each = {
    for lun, disk in var.additional_disks : lun => disk
    if local.is_windows == true && var.scale_set.enabled == false
  }

  resource_group_name = var.resource_group_name
  location            = var.location
  resource_suffix     = "${each.key}-${var.name}-${var.resource_suffix}"
  virtual_machine_id  = azurerm_windows_virtual_machine.win_vm[0].id
  disk_storage_type   = var.disk_storage_type

  lun = each.key

  disk_encryption_set_id = var.disk_encryption.disk_encryption_set_id
  disk_encryption_type   = var.disk_encryption.type

  tags = var.tags

  zone = var.zone
}


resource "azurerm_windows_virtual_machine_scale_set" "win_vmss" {
  count = local.is_windows == true && var.scale_set.enabled == true && var.scale_set.is_flexible_orchestration == false ? 1 : 0

  name                 = "vmss-${var.name}-${var.resource_suffix}"
  computer_name_prefix = var.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  extension_operations_enabled = true

  automatic_instance_repair {
    enabled      = var.scale_set.automatic_instance_repair
    grace_period = "PT30M"
  }

  upgrade_mode  = var.patching.enabled == true ? "Automatic" : "Manual"
  overprovision = false

  dynamic "automatic_os_upgrade_policy" {
    for_each = var.patching.enabled ? [var.patching] : []
    content {
      disable_automatic_rollback  = true
      enable_automatic_os_upgrade = var.patching.enabled
    }
  }

  enable_automatic_updates = var.automatic_updates_enabled

  vtpm_enabled               = var.vtpm_enabled
  secure_boot_enabled        = var.secure_boot_enabled
  encryption_at_host_enabled = (var.disk_encryption.type == "host" || var.disk_encryption.type == "des+")

  scale_in {
    force_deletion_enabled = false
    rule                   = "Default"
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

  sku       = var.sku
  instances = 1

  zone_balance       = var.scale_set.zone_balance
  zones              = var.scale_set.zones
  provision_vm_agent = true

  dynamic "extension" {
    for_each = { for k, extension in var.extensions : k => extension }
    content {
      publisher                  = extension.value.publisher
      name                       = extension.value.name
      settings                   = extension.value.settings
      type                       = extension.value.type
      type_handler_version       = try(extension.value.version, "1.0")
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = try(extension.value.automatic_upgrade_enabled, false)
    }
  }

  dynamic "data_disk" {
    for_each = { for k, disk in var.additional_disks : k => disk }
    content {
      lun                  = data_disk.value.lun
      caching              = data_disk.value.caching
      storage_account_type = data_disk.value.type
      create_option        = data_disk.value.create_option
      disk_size_gb         = data_disk.value.disk_size
    }
  }


  winrm_listener {
    protocol = "Http"
  }

  dynamic "boot_diagnostics" {
    for_each = var.monitoring.enabled == true ? [1] : []
    content {
      storage_account_uri = try(var.monitoring.config.storage_account_id, null)
    }
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = var.disk_storage_type
    disk_size_gb           = var.os_disk_size
    disk_encryption_set_id = var.disk_encryption.disk_encryption_set_id
  }

  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }
  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) <= 0 ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}