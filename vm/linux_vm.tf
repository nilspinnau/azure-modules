
resource "azurerm_linux_virtual_machine" "linux_vm" {

  count = local.is_windows == false && var.scale_set.enabled == false ? var.instance_count : 0

  name                            = format("%s%04d", var.server_name, count.index)
  computer_name                   = format("%s%04d", var.server_name, count.index)
  location                        = var.az_region
  resource_group_name             = var.resource_group_name
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  availability_set_id          = var.enable_availability_set == true && length(var.zones) > 0 == false && var.scale_set.enabled == false ? one(azurerm_availability_set.aset[*].id) : null
  virtual_machine_scale_set_id = var.scale_set.enabled == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : null

  zone = length(var.zones) > 0 ? count.index % length(var.zones) + 1 : null

  allow_extension_operations        = true
  encryption_at_host_enabled        = var.disk_encryption.enabled == true && (var.disk_encryption.config.type == "host" || var.disk_encryption.config.type == "des+")
  vm_agent_platform_updates_enabled = true

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled

  license_type       = var.license_type
  provision_vm_agent = true

  patch_mode            = var.patching.enabled == true ? var.patching.patch_mode : null
  patch_assessment_mode = var.patching.enabled == true ? var.patching.patch_assessment_mode : null

  size = var.vm_sku
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  os_disk {
    name                 = "osdisk-${format("%s%04d", var.server_name, count.index)}-${var.resource_postfix}"
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
    for_each = var.user_assigned_identity.enabled == true ? [var.user_assigned_identity] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = identity.value.config.create == true ? [azurerm_user_assigned_identity.uid.0.id] : [identity.value.config.id]
    }
  }
  dynamic "identity" {
    for_each = var.user_assigned_identity.enabled == false ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  tags = var.tags
}

module "linux_disks" {
  source = "./modules/disks"

  count = local.is_windows == false && var.scale_set.enabled == false ? var.instance_count : 0

  resource_group_name = var.resource_group_name
  az_region           = var.az_region
  resource_postfix    = "${format("%s%04d", var.server_name, count.index)}-${var.resource_postfix}"
  virtual_machine_id  = azurerm_linux_virtual_machine.linux_vm[count.index].id
  disk_storage_type   = var.disk_storage_type
  additional_disks    = var.additional_disks

  disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
  disk_encryption_type   = var.disk_encryption.config.type

  tags = var.tags

  zone = length(var.zones) > 0 ? count.index % length(var.zones) + 1 : null
}


data "azurerm_managed_disk" "linux_os_disk" {
  count = local.is_windows == false && var.scale_set.enabled == false ? var.instance_count : 0

  name                = "osdisk-${format("%s%04d", var.server_name, count.index)}-${var.resource_postfix}"
  resource_group_name = var.resource_group_name

  depends_on = [
    time_sleep.wait_vm_creation,
    azurerm_linux_virtual_machine.linux_vm
  ]
}


resource "azurerm_linux_virtual_machine_scale_set" "linux_vmss" {
  count = local.is_windows == false && var.scale_set.enabled == true && try(var.scale_set.config.is_flexible_orchestration, false) == false ? 1 : 0

  name                 = "vmss-${var.server_name}-${var.resource_postfix}"
  computer_name_prefix = var.server_name
  location             = var.az_region
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

  network_interface {
    name                          = "nic-${var.resource_postfix}-${var.server_name}"
    dns_servers                   = []
    enable_accelerated_networking = var.enable_accelerated_networking
    enable_ip_forwarding          = false
    primary                       = true
    ip_configuration {
      name                                         = "default"
      primary                                      = true
      subnet_id                                    = var.subnet_id
      version                                      = var.ip_version
      application_security_group_ids               = compact([try(azurerm_application_security_group.default.0.id, null)])
      load_balancer_backend_address_pool_ids       = var.loadbalancing.loadbalancer.enabled == true && var.loadbalancing.loadbalancer.backend_address_pool_id != null ? [var.loadbalancing.loadbalancer.backend_address_pool_id] : []
      application_gateway_backend_address_pool_ids = var.loadbalancing.application_gateway.enabled == true && var.loadbalancing.application_gateway.backend_address_pool_id != null ? [var.loadbalancing.application_gateway.backend_address_pool_id] : []
    }
  }

  sku       = var.vm_sku
  instances = var.instance_count


  zone_balance                    = length(var.zones) > 0 ? true : false
  zones                           = var.zones
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

  dynamic "identity" {
    for_each = var.user_assigned_identity.enabled == false ? [1] : []
    content {
      type = "SystemAssigned"
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
    for_each = var.user_assigned_identity.enabled == true ? [var.user_assigned_identity] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = identity.value.config.create == true ? [azurerm_user_assigned_identity.uid.0.id] : [identity.value.config.id]
    }
  }

  tags = var.tags
}