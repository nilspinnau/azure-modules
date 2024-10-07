variable "peering" {
  type = object({
    enabled = optional(bool, false)
    config = optional(object({
      first = object({
        resource_group_name          = string
        virtual_network_name         = string
        virtual_network_id           = string
        allow_forwarded_traffic      = optional(bool, false)
        allow_gateway_transit        = optional(bool, false)
        allow_virtual_network_access = optional(bool, false)
      })
      second = object({
        resource_group_name          = string
        virtual_network_name         = string
        virtual_network_id           = string
        allow_forwarded_traffic      = optional(bool, false)
        allow_gateway_transit        = optional(bool, false)
        allow_virtual_network_access = optional(bool, false)
      })
    }))
  })
  default = {
    enabled = false
  }
  nullable = false
}