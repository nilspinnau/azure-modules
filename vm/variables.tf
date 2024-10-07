variable "az_region" {
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

variable "vm_sku" {
  type        = string
  description = "Azure VM SKU, determines the Azure vCPU, vRAM etc. for the VMs. More information see: https://learn.microsoft.com/en-us/azure/virtual-machines/sizes"
}

variable "instance_count" {
  type        = number
  default     = 1
  description = "How many VMs should be deployed."
}

variable "os_disk_size" {
  type        = number
  default     = 128
  description = "The OS disk size of the VMs."
}

variable "resource_postfix" {
  type        = string
  description = "Postfix for all resources which will be deployed."
}

variable "additional_ips" {
  type     = number
  default  = 0
  nullable = false
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which to deploy the VMs."
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


variable "loadbalancing" {
  type = object({
    application_gateway = optional(object({
      enabled                 = optional(bool, false)
      backend_address_pool_id = optional(string, null)
    }), {})
    loadbalancer = optional(object({
      enabled                      = optional(bool, false)
      frontend_ip_configuration_id = optional(string, null)
      backend_address_pool_id      = optional(string, null)
    }), {})
  })
  default = { }
  nullable = false
}


variable "enable_availability_set" {
  type        = bool
  default     = false
  description = "Flag to determine if the VMs should be in an availability set."
}

variable "scale_set" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      automatic_scaling         = optional(bool, true)
      zone_balance              = optional(bool, true)
      automatic_instance_repair = optional(bool, false)
      is_flexible_orchestration = optional(bool, true)
    }), {})
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
  type = list(object({
    lun           = number
    letter        = string
    disk_size     = number
    label         = optional(string, "Data")
    create_option = optional(string, "Empty")
    caching       = optional(string, "ReadWrite")
  }))
  default  = []
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

variable "server_name" {
  type = string
}

variable "zones" {
  type     = list(string)
  default  = ["1", "2", "3"]
  nullable = false
}

variable "enable_accelerated_networking" {
  type        = bool
  description = "Enable Accelerated Networking on the network interface card for the VM."
  default     = false
  nullable    = false
}

variable "user_assigned_identity" {
  type = object({
    enabled = optional(bool, false)
    config = object({
      create = optional(bool, true)
      id     = optional(string, null)
      roles  = optional(list(string), [])
    })
  })
  default = {
    enabled = false
    config = {
      create = true
      roles  = []
    }
  }
  nullable = false
}

variable "extensions" {
  type = list(object({
    name                      = string
    publisher                 = string
    type                      = string
    settings                  = optional(any, null)
    protected_settings        = optional(any, null)
    automatic_upgrade_enabled = optional(bool, true)
    version                   = optional(string, "1.0")
  }))
  nullable = false
}

variable "ip_version" {
  default  = "IPv4"
  type     = string
  nullable = false
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

variable "enable_automatic_updates" {
  type    = bool
  default = false
}

variable "machine_configurations" {
  type = list(object({
    name = string
    configuration = object({
      assignment_type = optional(string, "Audit")
      version         = optional(string, "1.*")
      content_hash    = optional(string, "")
      content_uri     = optional(string, "")
      parameters = optional(list(object({
        name  = string
        value = string
      })), [])
    })
  }))
  default = []
}

variable "disk_encryption" {
  type = object({
    enabled = optional(bool, true)
    config = optional(object({
      type                   = optional(string, "host") # possible ade, host, des, des+ = des + host
      vault_id               = optional(string, null)
      vault_uri              = optional(string, null)
      disk_encryption_set_id = optional(string, null)
    }), {})
  })
  default = {
    enabled = false
  }
}

variable "patching" {
  type = object({
    enabled               = optional(bool, true)
    patch_mode            = optional(string, "AutomaticByPlatform")
    patch_assessment_mode = optional(string, "AutomaticByPlatform")
    patch_schedule = optional(object({
      schedule_name = optional(string, "")
      schedule_id   = string
      }), {
      schedule_id = null
    })
  })
  default = {
    enabled = false
  }
}

variable "automanage" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      configuration_id = optional(string, "/providers/Microsoft.Automanage/bestPractices/AzureBestPracticesProduction")
    }), {})
  })
  default = {
    enabled = false
  }
  nullable = false
}


variable "private_link_service" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      nat_subnet_id = string
      private_ip    = string
    }))
  })
  default = {
    enabled = false
  }
}

variable "secure_boot_enabled" {
  type    = bool
  default = false
}

variable "enable_asg" {
  type    = bool
  default = false
}