
variable "location" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}

variable "resource_suffix" {
  type = string
}

variable "dns_servers" {
  type    = set(string)
  default = []
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
}

variable "address_space" {
  type = string
}

variable "flow_logs" {
  type = object({
    storage_account_id = string
    traffic_analytics = optional(object({
      enabled               = optional(bool, false)
      workspace_id          = string
      workspace_region      = string
      workspace_resource_id = string
    }))
  })
  default  = null
  nullable = true
}

variable "subnets" {
  # if we do not use list/set then we will have a problem with ordering and recreation of subnets....
  type = list(object({
    name               = string
    newbit             = number
    attach_route_table = optional(bool, true)
    service_endpoints  = optional(set(string), [])
    nat_gateway        = optional(bool, false)
    enable_nsg         = optional(bool, true)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = set(string)
      })
    }))
    nsg_rules = optional(map(object({
      priority                     = number
      description                  = optional(string, "TBD")
      direction                    = string
      access                       = string
      protocol                     = string
      destination_port_ranges      = set(string)
      source_address_prefixes      = optional(set(string), [])
      destination_address_prefixes = optional(set(string), [])
    })), {})
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
}

variable "dns_zone_links" {
  type = map(object({
    resource_group_name   = string
    private_dns_zone_name = string
  }))
  default = {}
}

variable "route_table" {
  type = object({
    enabled = optional(bool, true)
    routes = optional(map(object({
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), {})
  })
  default  = {}
  nullable = false
}