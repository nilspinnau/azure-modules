
resource "azurerm_linux_virtual_machine" "linux_vm" {

  count = local.is_windows == false && var.scale_set.enabled == false ? 1 : 0

  name                            = var.name
  computer_name                   = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  virtual_machine_scale_set_id = var.scale_set.enabled == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : null

  zone = var.zone

  allow_extension_operations        = true
  encryption_at_host_enabled        = var.disk_encryption.enabled == true && (var.disk_encryption.config.type == "host" || var.disk_encryption.config.type == "des+")
  vm_agent_platform_updates_enabled = true

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled

  license_type       = var.license_type
  provision_vm_agent = true

  patch_mode            = var.patching.enabled == true ? var.patching.patch_mode : null
  patch_assessment_mode = var.patching.enabled == true ? var.patching.patch_assessment_mode : null

  size                  = var.sku
  network_interface_ids = [for nic in azurerm_network_interface.default : nic.id]

  os_disk {
    name                 = "osdisk-${var.name}-${var.resource_suffix}"
    caching              = "ReadWrite"
    storage_account_type = var.disk_storage_type
    disk_size_gb         = var.os_disk_size
  }

  dynamic "boot_diagnostics" {
    for_each = var.monitoring.enabled == true && try(length(var.monitoring.config.storage_account_id) > 0, false) == true ? [1] : []
    content {
      storage_account_uri = var.monitoring.config.storage_account_id
    }
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

module "linux_disks" {
  source = "./modules/disks"


  for_each = {
    for k, disk in var.additional_disks : k => disk
    if local.is_windows == false && var.scale_set.enabled == false
  }

  resource_group_name = var.resource_group_name
  location            = var.location
  resource_suffix     = "${each.key}-${var.name}-${var.resource_suffix}"
  virtual_machine_id  = azurerm_linux_virtual_machine.linux_vm[0].id
  disk_storage_type   = var.disk_storage_type

  lun = each.key

  disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
  disk_encryption_type   = var.disk_encryption.config.type

  tags = var.tags

  zone = var.zone
}


data "azurerm_managed_disk" "linux_os_disk" {
  count = local.is_windows == false && var.scale_set.enabled == false ? 1 : 0

  name                = "osdisk-${var.name}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name

  depends_on = [
    time_sleep.wait_vm_creation,
    azurerm_linux_virtual_machine.linux_vm
  ]
}


resource "azurerm_linux_virtual_machine_scale_set" "linux_vmss" {
  count = local.is_windows == false && var.scale_set.enabled == true && try(var.scale_set.config.is_flexible_orchestration, false) == false ? 1 : 0

  name                 = "vmss-${var.name}-${var.resource_suffix}"
  computer_name_prefix = var.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  automatic_instance_repair {
    enabled = var.scale_set.config.automatic_instance_repair
  }

  upgrade_mode = var.patching.enabled == true ? "Automatic" : "Manual"
  dynamic "automatic_os_upgrade_policy" {
    for_each = var.patching.enabled ? [var.patching] : []
    content {
      disable_automatic_rollback  = false
      enable_automatic_os_upgrade = var.patching.enabled
    }
  }

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled

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

  zone_balance                    = var.scale_set.config.zone_balance
  zones                           = var.scale_set.config.zones
  provision_vm_agent              = true
  disable_password_authentication = false

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

  encryption_at_host_enabled = var.disk_encryption.enabled == true && (var.disk_encryption.config.type == "host" || var.disk_encryption.config.type == "des+")

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
    disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
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