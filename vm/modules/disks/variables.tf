variable "location" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the disks."
}


variable "virtual_machine_id" {
  type        = string
  description = "ID of the VM to which the disks get attached to."
}

variable "resource_postfix" {
  type        = string
  description = "Postfix for all resources which will be deployed."
}

variable "disk_storage_type" {
  type    = string
  default = "StandardSSD_LRS"
  validation {
    condition = contains([
      "Standard_LRS", "StandardSSD_ZRS", "Premium_LRS", "PremiumV2_LRS", "Premium_ZRS", "StandardSSD_LRS"
    ], var.disk_storage_type)
    error_message = "Disk type is not supported for os disk. Supported types are: ['Standard_LRS', 'StandardSSD_ZRS', 'Premium_LRS', 'PremiumV2_LRS', 'Premium_ZRS', 'StandardSSD_LRS']"
  }
}

variable "additional_disks" {
  type = list(object({
    lun           = number
    letter        = string
    disk_size     = number
    label         = string
    create_option = string
    caching       = string
  }))
  default = []
}

variable "zone" {
  type    = number
  default = null
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
}

variable "disk_encryption_set_id" {
  type    = string
  default = null
}

variable "disk_encryption_type" {
  type    = string
  default = ""
}