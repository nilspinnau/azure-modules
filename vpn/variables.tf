
variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_suffix" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "sku" {
  type = string
}

variable "vpn_type" {
  type = string
}

variable "active_active" {
  type    = bool
  default = false
}

variable "enable_bgp" {
  type    = bool
  default = false
}

variable "private_ip_address_enabled" {
  type    = bool
  default = false
}

variable "remote_vnet_traffic_enabled" {
  type    = bool
  default = true
}

variable "virtual_wan_traffic_enabled" {
  type    = bool
  default = false
}

variable "generation" {
  type    = string
  default = "Generation2"
}

variable "ip_configuration" {
  type = set(object({
    name                          = optional(string, "")
    private_ip_address_allocation = optional(string, null)
    public_ip = object({
      sku                     = optional(string, "Standard")
      sku_tier                = optional(string, "Regional")
      zones                   = optional(list(string), [])
      allocation_method       = optional(string, "Static")
      ddos_protection_plan_id = optional(string, "")
      idle_timeout_in_minutes = optional(number, 4)
      ip_version              = optional(string, "IPv4")
      public_ip_prefix_id     = optional(string, null)
      domain_name_label       = optional(string, null)
      reverse_fqdn            = optional(string, null)
    })
  }))
}

variable "client_configuration" {
  type = set(object({
    address_space = string
    # Optional attributes
    aad_tenant            = optional(string, null)
    aad_audience          = optional(string, null)
    aad_issuer            = optional(string, null)
    radius_server_address = optional(string, null)
    radius_server_secret  = optional(string, null)
    vpn_client_protocols  = optional(set(string), null)
    vpn_auth_types        = optional(set(string), null)
    root_certificate = optional(set(object({
      name             = string
      public_cert_data = string
    })))
    revoked_certificate = optional(set(object({
      name       = string
      thumbprint = string
    })))
  }))
  default = []
}

variable "bgp_settings" {
  type = object({
    asn         = number
    peer_weight = number
    peering_addresses = optional(set(object({
      ip_configuration_name = optional(string, "")
      apipa_addresses       = optional(list(string), [])
    })), [])
  })
  default = null
}

variable "custom_route" {
  type = object({
    address_prefixes = list(string)
  })
  default = null
}

variable "connection" {
  type = object({
    name                            = string
    type                            = string
    connection_mode                 = optional(string, "")
    enable_bgp                      = optional(bool, false)
    shared_key                      = optional(string, "")
    bi_directional_enabled          = optional(bool, true)
    peer_virtual_network_gateway_id = optional(string, "")
  })
  default = null
}

variable "log_analytics_workspace_id" {
  type     = string
  default  = ""
  nullable = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "local_network_gateway" {
  type = object({
    address_space   = optional(list(string), [])
    gateway_fqdn    = optional(string, "")
    gateway_address = optional(string, "")
    bgp_settings = optional(object({
      asn                 = number
      peer_weight         = optional(number, null)
      bgp_peering_address = string
    }))
  })
  default = null
}