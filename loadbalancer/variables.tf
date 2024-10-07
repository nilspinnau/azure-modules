variable "az_region" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "name" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}

variable "resource_postfix" {
  type        = string
  description = "Postfix for all resources which will be deployed."
}

variable "frontend_ip_configurations" {
  type = list(object({
    name               = string
    private_ip_address = optional(string, null)
    ip_version         = optional(string, "IPv4")
    subnet_id          = optional(string, null)
    zones              = optional(list(string), ["1"])
    is_public          = optional(bool, false)
    domain_name        = optional(string, null)
  }))
}

variable "health_probes" {
  type = list(object({
    name                    = string
    port                    = number
    path                    = optional(string, "/")
    protocol                = optional(string, "Tcp")
    interval_in_seconds     = optional(number, 5)
    probe_threshold         = optional(number, 5)
    number_of_failed_probes = optional(number, 3)
  }))
  default = []
}

variable "backend_address_pools" {
  type = list(string)
}

variable "inbound_rules" {
  type = list(object({
    name                           = string
    backend_port                   = number
    frontend_port                  = number
    protocol                       = string
    frontend_ip_configuration_name = string
    probe_name                     = optional(string, null)
    backend_address_pool_names     = list(string)
    enable_floating_ip             = optional(bool, null)
    idle_timeout_in_minutes        = optional(number, null)
    enable_tcp_reset               = optional(bool, null)
    disable_outbound_snat          = optional(bool, true)
  }))
  default = []
}

variable "nat_rules" {
  type = list(object({
    name                           = string
    backend_port                   = number
    frontend_port                  = number
    protocol                       = string
    frontend_ip_configuration_name = string
    backend_address_pool_name      = optional(string, null)
    enable_floating_ip             = optional(bool, null)
    idle_timeout_in_minutes        = optional(number, null)
    enable_tcp_reset               = optional(bool, null)
  }))
  default  = []
  nullable = false
}

variable "outbound_rules" {
  type = list(object({
    name                      = string
    protocol                  = string
    backend_address_pool_name = string
    enable_floating_ip        = optional(bool, null)
    idle_timeout_in_minutes   = optional(number, null)
    enable_tcp_reset          = optional(bool, null)
    frontend_ip_configurations = optional(map(object({
      name = string
    })), {})
    number_of_allocated_outbound_ports = optional(number, 8)
  }))
  default = []
}

variable "nat_pool" {
  type = list(object({
    name          = string
    backend_port  = number
    frontend_port = number
    protocol      = string
  }))
  default = []
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
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
        id   = string
        name = optional(string)
        key  = optional(string, null)
      }), null)
    }))
  })
  default = {
    enabled = false
  }
}