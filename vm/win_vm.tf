resource "azurerm_windows_virtual_machine" "win_vm" {

  count = local.is_windows == true && var.scale_set.enabled == false ? var.instance_count : 0

  name                = format("%s%04d", var.server_name, count.index)
  computer_name       = format("%s%04d", var.server_name, count.index)
  location            = var.location
  resource_group_name = var.resource_group_name
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  availability_set_id          = var.enable_availability_set == true && length(var.zones) > 0 == false && var.scale_set.enabled == false ? one(azurerm_availability_set.aset[*].id) : null
  virtual_machine_scale_set_id = var.scale_set.enabled == true ? azurerm_orchestrated_virtual_machine_scale_set.vmss.0.id : null

  zone = length(var.zones) > 0 ? tolist(var.zones)[count.index % length(var.zones)] : null

  allow_extension_operations        = true
  encryption_at_host_enabled        = var.disk_encryption.enabled == true && (var.disk_encryption.config.type == "host" || var.disk_encryption.config.type == "des+")
  vm_agent_platform_updates_enabled = true


  hotpatching_enabled      = var.hotpatching_enabled
  enable_automatic_updates = var.enable_automatic_updates

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled


  license_type       = var.license_type
  provision_vm_agent = true

  patch_mode            = var.patching.enabled == true ? var.patching.patch_mode : null
  patch_assessment_mode = var.patching.enabled == true ? var.patching.patch_assessment_mode : null

  bypass_platform_safety_checks_on_user_schedule_enabled = var.patching.patch_schedule.schedule_name != ""

  size = var.vm_sku
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

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
    name                   = "osdisk-${format("%s%04d", var.server_name, count.index)}-${var.resource_suffix}"
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
    for_each = var.user_assigned_identity.enabled == true ? [1] : []
    content {
      type         = "SystemAssigned, UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.uid.0.id]
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


data "azurerm_managed_disk" "win_os_disk" {
  count = local.is_windows == true && var.scale_set.enabled == false ? var.instance_count : 0

  name                = "osdisk-${format("%s%04d", var.server_name, count.index)}-${var.resource_suffix}"
  resource_group_name = var.resource_group_name

  depends_on = [
    time_sleep.wait_vm_creation,
    azurerm_windows_virtual_machine.win_vm
  ]
}

module "windows_disks" {
  source = "./modules/disks"

  count = local.is_windows == true && var.scale_set.enabled == false ? var.instance_count : 0

  resource_group_name = var.resource_group_name
  location            = var.location
  resource_suffix     = "${format("%s%04d", var.server_name, count.index)}-${var.resource_suffix}"
  virtual_machine_id  = azurerm_windows_virtual_machine.win_vm[count.index].id
  disk_storage_type   = var.disk_storage_type
  additional_disks    = var.additional_disks

  disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
  disk_encryption_type   = var.disk_encryption.config.type

  tags = var.tags

  zone = length(var.zones) > 0 ? tolist(var.zones)[count.index % length(var.zones)] : null
}


resource "azurerm_windows_virtual_machine_scale_set" "win_vmss" {
  count = local.is_windows == true && var.scale_set.enabled == true && var.scale_set.config.is_flexible_orchestration == false ? 1 : 0

  name                 = "vmss-${var.server_name}-${var.resource_suffix}"
  computer_name_prefix = var.server_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password

  extension_operations_enabled = true

  automatic_instance_repair {
    enabled      = var.scale_set.config.automatic_instance_repair
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

  enable_automatic_updates = var.enable_automatic_updates

  vtpm_enabled        = var.vtpm_enabled
  secure_boot_enabled = var.secure_boot_enabled

  scale_in {
    force_deletion_enabled = false
    rule                   = "Default"
  }

  network_interface {
    name                          = "nic-${var.resource_suffix}-${var.server_name}"
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

  zone_balance       = length(var.zones) > 0 ? true : false
  zones              = var.zones
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


  dynamic "identity" {
    for_each = var.user_assigned_identity.enabled == true ? [var.user_assigned_identity] : []
    content {
      type         = "UserAssigned"
      identity_ids = identity.value.config.create == true ? [azurerm_user_assigned_identity.uid.0.id] : [identity.value.config.id]
    }
  }
  encryption_at_host_enabled = var.disk_encryption.enabled == true && (var.disk_encryption.config.type == "host" || var.disk_encryption.config.type == "des+")

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
    disk_encryption_set_id = var.disk_encryption.enabled == true && strcontains(var.disk_encryption.config.type, "des") ? var.disk_encryption.config.disk_encryption_set_id : null
  }


  source_image_reference {
    publisher = var.source_image_reference.publisher
    offer     = var.source_image_reference.offer
    sku       = var.source_image_reference.sku
    version   = var.source_image_reference.version
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uid.0.id]
  }

  tags = var.tags
}