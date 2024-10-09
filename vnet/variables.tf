
variable "az_region" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "stage" {
  type = string
  validation {
    condition     = contains(["dev", "test", "qa", "prod"], var.stage)
    error_message = "Stage must be of ['dev', 'test', 'qa', 'prod']"
  }
  default     = "dev"
  description = "Stage of the deployment."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}

variable "resource_postfix" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
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
    enabled = optional(bool, false)
    config = optional(object({
      storage_account_id = string
      traffic_analytics = optional(object({
        enabled = optional(bool, false)
        workspace = optional(object({
          workspace_id = string
          location     = string
          resource_id  = string
        }))
      }))
    }))
  })
  default = {
    enabled = false
  }
}

variable "subnets" {
  type = list(object({
    name               = string
    newbit             = number
    attach_route_table = optional(bool, true)
    service_endpoints  = optional(list(string), [])
    nat_gateway        = optional(bool, false)
    enable_nsg         = optional(bool, true)
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
    nsg_rules = optional(list(object({
      name                         = string
      description                  = optional(string, "TBD")
      direction                    = string
      access                       = string
      protocol                     = string
      destination_port_ranges      = list(string)
      source_address_prefixes      = optional(list(string), [])
      destination_address_prefixes = optional(list(string), [])
      source_address_prefix        = optional(string, null)
      destination_address_prefix   = optional(string, null)
    })), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
}

variable "dns_zone_links" {
  type = list(object({
    name                  = optional(string)
    resource_group_name   = string
    private_dns_zone_name = string
  }))
  default = []
}

variable "route_table" {
  type = object({
    enabled = optional(bool, true)
    routes = optional(list(object({
      address_prefix         = string
      name                   = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
  })
  default = {
    enabled = true
    routes  = []
  }
}