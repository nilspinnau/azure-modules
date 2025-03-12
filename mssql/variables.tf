variable "location" {
  type = string
}


variable "resource_group_name" {
  type = string
}

variable "name" {
  type = string
}

variable "sql_version" {
  type    = string
  default = "12.0"
}


variable "databases" {
  type = map(object({
    min_capacity            = optional(number, 0)
    max_size_gb             = optional(number, null)
    sku_name                = string
    zone_redundant          = optional(bool, true)
    storage_account_type    = optional(string, "Local")
    collation               = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type            = optional(string, "BasePrice")
    geo_backup_enabled      = optional(bool, true)
    active_failover_enabled = optional(bool, false)
    ledger_enabled          = optional(bool, false)
    read_replica_count      = optional(number, 1)
    read_scale              = optional(bool, true)
    enable_enclave          = optional(bool, false)
    long_term_retention_policy = optional(object({
      monthly_retention = optional(string, "P5W")
      weekly_retention  = optional(string, "P2W")
      yearly_retention  = optional(string, "P13M")
      week_of_year      = optional(number, 52)
      }), {
      monthly_retention = "P5W"
      weekly_retention  = "P2W"
      yearly_retention  = "P13M"
      week_of_year      = 52
    })
    short_term_retention_policy = optional(object({
      retention_days           = optional(number, 14)
      backup_interval_in_hours = optional(number, 12)
      }), {
      retention_days           = 14
      backup_interval_in_hours = 12
    })
  }))
  default  = {}
  nullable = false
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "outbound_network_restriction_enabled" {
  type    = bool
  default = false
}

variable "entra_admin" {
  type = object({
    object_id = string
    username  = string
  })
  nullable = false
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "resource_suffix" {
  type = string
}

variable "extaudit_diag_logs" {
  description = "Database Monitoring Category details for Azure Diagnostic setting"
  default     = ["SQLSecurityAuditEvents", "SQLInsights", "AutomaticTuning", "QueryStoreRuntimeStatistics", "QueryStoreWaitStatistics", "Errors", "DatabaseWaitStatistics", "Timeouts", "Blocks", "Deadlocks", "DevOpsOperationsAudit"]
  nullable    = false
}

variable "disabled_alerts" {
  description = "Specifies an array of alerts that are disabled. Allowed values are: Sql_Injection, Sql_Injection_Vulnerability, Access_Anomaly, Data_Exfiltration, Unsafe_Action."
  type        = list(any)
  default     = []
}

variable "auditing" {
  type = object({
    storage_account = optional(object({
      name                         = string
      id                           = string
      primary_blob_endpoint        = string
      access_key                   = string
      subscription_id              = string
      vulnerability_container_path = optional(string, "")
    }), null)
    log_analytics = optional(object({
      workspace_name        = string
      workspace_resource_id = string
    }), null)
    extended_auditing_policy_enabled = optional(bool, false)
    support_auditing_policy_enabled  = optional(bool, false)
    security_alert_policy_enabled    = optional(bool, false)
    vulnerability_assessment_enabled = optional(bool, false)
    log_retention_days               = optional(number, 90)
  })
  nullable = false
}

variable "users_to_email" {
  type    = set(string)
  default = []
}

variable "firewall_rules" {
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default  = {}
  nullable = false
}

variable "firewall_virtual_network_rules" {
  type    = set(string)
  default = []
}

variable "outbound_firewall_rules" {
  type    = set(string)
  default = []
}

variable "failover" {
  type = object({
    location            = string
    resource_group_name = optional(string, null)
  })
  default = null
}


variable "private_endpoints" {
  type = map(object({
    is_failover                             = optional(bool, false)
    name                                    = optional(string, null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
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