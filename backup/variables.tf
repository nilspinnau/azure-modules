variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
}

variable "backup" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      vault = object({
        snapshot_resource_group_id         = optional(string, "") # required with type disk
        snapshot_resource_group_name       = optional(string, "")
        recovery_vault_resource_group_name = optional(string, "") # required with type vm
        principal_id                       = string
        rsv_policy_id                      = string
        backup_policy_id                   = string
        location                           = string
        backup_vault_id                    = string
        recovery_vault_name                = string
      })
      items = optional(list(object({
        id   = string
        name = string
        type = string # disk or vm
      })), [])
    }))
  })
  default  = {}
  nullable = false
}


variable "site_recovery" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      vault_id            = string
      vault_principal_id  = string
      resource_group_name = string
      app_name            = string
      replication_policy = object({
        name                                                 = string
        recovery_point_retention_in_minutes                  = number
        application_consistent_snapshot_frequency_in_minutes = number
      })
      secondary = object({
        location               = string
        resource_group_id      = string
        virtual_network_id     = string
        subnet_name            = string
        disk_encryption_set_id = optional(string, null)
        key_vault_id           = optional(string, "")
        automation_account_id  = optional(string, null)
      })
      primary = object({
        location                      = string
        virtual_network_id            = string
        staging_storage_account_id    = string
        key_vault_id                  = optional(string, "")
        key_vault_resource_group_name = optional(string, "")
        automation_account_id         = optional(string, null)
      })
      protected_items = optional(map(object({
        id   = string
        name = string
        zone = number
        os_disk = object({
          id                     = string
          storage_account_type   = string
          disk_encryption_type   = string
          disk_encryption_set_id = optional(string, null)
        })
        resource_group_name  = string
        network_interface_id = string
        managed_disks = map(object({
          id                     = string
          name                   = string
          lun                    = number
          letter                 = string
          storage_account_type   = string
          disk_encryption_type   = string
          disk_encryption_set_id = optional(string, null)
        }))
      })), {})
    }))
  })
  nullable = false
  default  = {}
}