variable "location" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}

variable "resource_group_id" {
  type = string
}

variable "name" {
  type     = string
  nullable = false
}

variable "sku" {
  type        = string
  description = "Azure VM SKU, determines the Azure vCPU, vRAM etc. for the VMs. More information see: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes"
}

variable "os_disk_size" {
  type        = number
  default     = 128
  description = "The OS disk size of the VMs."
}

variable "resource_suffix" {
  type        = string
  description = "Suffix for all resources which will be deployed."
}

variable "network_interface" {
  type = map(object({
    accelerated_networking_enabled = optional(bool, true)
    ip_configuration = map(object({
      subnet_id                                    = string
      private_ip_address_allocation                = optional(string, "Dynamic")
      primary                                      = optional(bool, false)
      private_ip_address                           = optional(string, null)
      private_ip_address_version                   = optional(string, "IPv4")
      application_gateway_backend_address_pool_ids = optional(set(string), [])
      load_balancer_backend_address_pool_ids       = optional(set(string), [])
      application_security_group_ids               = optional(set(string), [])
    }))
  }))
  default  = {}
  nullable = false
}

variable "license_type" {
  type        = string
  default     = null
  description = "License to use for Azure Hybrid Use Benefit."
}

variable "admin_password" {
  sensitive   = true
  type        = string
  description = "Password for the VM admin account."
}

variable "admin_username" {
  type        = string
  description = "Username for the VM admin account."
  default     = "nilspinnau"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
}

variable "dns_zone_name" {
  type    = string
  default = null
}

variable "load_balancer_backend_address_pool_ids" {
  type     = set(string)
  default  = []
  nullable = false
}

variable "application_gateway_backend_address_pool_ids" {
  type     = set(string)
  default  = []
  nullable = false
}

variable "scale_set" {
  type = object({
    enabled                   = optional(bool, false)
    automatic_scaling         = optional(bool, true)
    zone_balance              = optional(bool, true)
    zones                     = optional(set(string), ["1", "2", "3"])
    automatic_instance_repair = optional(bool, false)
    is_flexible_orchestration = optional(bool, true)
    sku_profile = optional(object({
      allocation_strategy = optional(string, "Lowest")
      vm_sizes            = optional(set(string), [])
    }), null)
  })
  default = {
    enabled = false
  }
  nullable = false
}


variable "disk_storage_type" {
  type    = string
  default = "StandardSSD_LRS"
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "Premium_ZRS", "StandardSSD_LRS"
    ], var.disk_storage_type)
    error_message = "Disk type is not supported for os disk. Supported types are: ['Standard_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'Premium_ZRS', 'StandardSSD_LRS']"
  }
  nullable = false
}


variable "additional_disks" {
  type = map(object({
    disk_size     = number
    label         = optional(string, "Data")
    create_option = optional(string, "Empty")
    caching       = optional(string, "ReadWrite")
  }))
  default  = {}
  nullable = false
}

variable "hotpatching_enabled" {
  type     = bool
  default  = false
  nullable = false
}

variable "source_image_reference" {
  type = object({
    offer     = optional(string, "WindowsServer")
    publisher = optional(string, "MicrosoftWindowsServer")
    sku       = optional(string, "2022-datacenter-azure-edition-hotpatch")
    version   = optional(string, "latest")
  })
}

variable "zone" {
  type     = string
  default  = "2"
  nullable = false
}

variable "gallery_applications" {
  type = map(object({
    id                     = optional(string, "")
    location               = optional(string, "")
    name                   = optional(string, "")
    gallery_application_id = string
  }))
  default = {}
}

variable "extensions" {
  type = map(object({
    publisher                 = string
    type                      = string
    settings                  = optional(any, null)
    protected_settings        = optional(any, null)
    automatic_upgrade_enabled = optional(bool, false)
    version                   = optional(string, "1.0")
  }))
  default  = {}
  nullable = false
}

variable "extensions_to_ignore" {
  type    = set(string)
  default = []
}

variable "monitoring" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      workspace = object({
        workspace_id = string
        name         = string
        resource_id  = string
        key          = string
      })
      storage_account = optional(object({
        resource_id = string
        name        = string
        key         = string
      }), null)
      vm_insights = optional(object({
        data_collection_rule_id = string
      }))
      change_tracking = optional(object({
        data_collection_rule_id = string
      }))
      vm_diagnostics          = optional(bool, false)
      performance_diagnostics = optional(bool, true)
      automation = optional(object({
        resource_id = string
      }))
    }))
  })
  default = {
    enabled = false
  }
}

variable "vtpm_enabled" {
  type    = bool
  default = false
}

variable "automatic_updates_enabled" {
  type    = bool
  default = false
}

variable "machine_configurations" {
  type = map(object({
    assignment_type = optional(string, "Audit")
    version         = optional(string, "1.*")
    content_hash    = optional(string, "")
    content_uri     = optional(string, "")
    parameters      = optional(map(string), {})
  }))
  default = {}
}

variable "disk_encryption" {
  type = object({
    type                   = optional(string, "none") # possible ade, host, des, des+ = des + host, none
    vault_id               = optional(string, null)
    vault_uri              = optional(string, null)
    disk_encryption_set_id = optional(string, null)
  })
  default  = {}
  nullable = false
}

variable "patching" {
  type = object({
    enabled               = optional(bool, true)
    patch_mode            = optional(string, "AutomaticByPlatform")
    patch_assessment_mode = optional(string, "AutomaticByPlatform")
    schedule = optional(object({
      name = optional(string, "")
      id   = string
    }), null)
  })
  default = {
    enabled = false
  }
}

variable "automanage" {
  type = object({
    enabled          = optional(bool, false)
    configuration_id = optional(string, "/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesProduction")
  })
  default = {
    enabled = false
  }
  nullable = false
}


variable "private_link_service" {
  type = map(object({
    auto_approval_subscription_ids = optional(set(string), [])
    visibility_subscription_ids    = optional(set(string), [])
    enable_proxy_protocol          = optional(bool, false)
    nat_ip_configuration = map(object({
      subnet_id                  = string
      private_ip                 = optional(string, null)
      private_ip_address_version = optional(string, "IPV4")
      primary                    = bool
    }))
    load_balancer_frontend_ip_configuration_ids = optional(set(string), [])
  }))
  default  = {}
  nullable = false
}

variable "secure_boot_enabled" {
  type    = bool
  default = false
}

variable "user_assigned_identity_ids" {
  type     = set(string)
  default  = []
  nullable = false
}