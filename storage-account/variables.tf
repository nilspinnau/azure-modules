variable "location" {
  type    = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "resource_postfix" {
  type = string
}


variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
}

variable "account_kind" {
  description = "The type of storage account. Valid options are BlobStorage, BlockBlobStorage, FileStorage and StorageV2."
  default     = "StorageV2"
  type        = string
  validation {
    condition     = contains(["BlobStorage", "BlockBlobStorage", "FileStorage", "StorageV2"], var.account_kind)
    error_message = "Possible values are: 'BlobStorage', 'BlockBlobStorage', 'FileStorage', 'StorageV2'"
  }
}

variable "account_tier" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Possible values are: 'Standard', 'Premium'"
  }
}

variable "account_replication_type" {
  type    = string
  default = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Possible values are: 'LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', 'RAGZRS'"
  }
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage and StorageV2 accounts. Valid options are Hot and Cool."
  default     = "Hot"
  type        = string
  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Possible values are: 'Hot', 'Cool'"
  }
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  default     = "TLS1_2"
  type        = string
}

variable "blob_soft_delete_retention_days" {
  description = "Specifies the number of days that the blob should be retained, between '1' and '365' days. Defaults to '7'"
  default     = 7
  type        = number
}

variable "container_soft_delete_retention_days" {
  description = "Specifies the number of days that the blob should be retained, between '1' and '365' days. Defaults to '7'"
  default     = 7
  type        = number
}

variable "change_feed_retention_in_days" {
  type    = number
  default = 7
  validation {
    condition     = var.change_feed_retention_in_days >= 1 && var.change_feed_retention_in_days <= 146000
    error_message = "The possible values are between 1 and 146000 days (400 years). Default is 7"
  }
  nullable = false
}

variable "queue_retention_policy_days" {
  description = "Specifies the number of days that the queue logs should be retained"
  default     = 7
  type        = number
}

variable "enable_point_in_time_restore" {
  type    = bool
  default = true
}

variable "enable_versioning" {
  description = "Is versioning enabled? Default to 'true'"
  default     = true
  type        = bool
}

variable "enable_last_access_time" {
  description = "Is the last access time based tracking enabled? Default to 'true'"
  default     = true
  type        = bool
}

variable "enable_change_feed" {
  description = "Is the blob service properties for change feed events enabled?"
  default     = true
  type        = bool
}

variable "enable_advanced_threat_protection" {
  description = "Boolean flag which controls if advanced threat protection is enabled."
  default     = false
  type        = bool
}


variable "public_access" {
  description = "Network rules restricting access to the storage account."
  type = object({
    enabled = optional(bool, true)
    network_rules = optional(object({
      bypass     = optional(list(string), [])
      ip_rules   = optional(list(string), [])
      subnet_ids = optional(list(string), [])
    }), {
      bypass     = []
      ip_rules   = []
      subnet_ids = []
    })
  })
  default = {
    enabled = true
  }
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_names = list(string)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "containers_list" {
  description = "List of containers to create and their access levels."
  type        = list(string)
  default     = []
}

variable "file_shares" {
  description = "List of containers to create and their access levels."
  type = list(object({
    name  = string
    quota = number
  }))
  default = []
}

variable "queues" {
  description = "List of storages queues"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "List of storage tables."
  type        = list(string)
  default     = []
}

variable "lifecycles" {
  description = "Configure Azure Storage firewalls and virtual networks"
  type = list(object({
    prefix_match               = set(string)
    tier_to_cool_after_days    = optional(number, null)
    tier_to_cold_after_days    = optional(number, null)
    tier_to_archive_after_days = optional(number, null)
    delete_after_days          = number
    snapshot_delete_after_days = number
    version_delete_after_days  = number
  }))
  default = []
}

variable "enable_sas_key" {
  default = false
  type    = bool
}

variable "data_lake_gen_2" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      nfsv3_enabled = optional(bool, false)
      sftp_enabled  = optional(bool, false)
    }))
  })
}


variable "monitoring" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      workspace = object({
        workspace_id = string
        resource_id  = string
      })
    }))
  })
  default = {
    enabled = false
  }
}