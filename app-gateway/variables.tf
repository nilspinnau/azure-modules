variable "location" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the network security group into."
}

variable "resource_suffix" {
  type = string
}

variable "name" {
  type = string
}

variable "sku" {
  type = object({
    name     = string
    tier     = string
    capacity = optional(number, null)
  })
}

variable "autoscale_configuration" {
  type = object({
    min_capacity = optional(number, 0)
    max_capacity = optional(number, null)
  })
  default     = {}
  nullable    = false
  description = ""
  # autoscale_configuration = { min_capacity = "", max_capacity = "" }
}


variable "subnet_id" {
  type        = string
  description = "The ID of the Subnet which the Application Gateway should be connected to."
}


variable "waf_configuration" {
  type = object({
    enabled          = optional(bool, true)
    firewall_mode    = optional(string, "Detection")
    rule_set_type    = optional(string, "OWASP")
    rule_set_version = optional(string, "3.2")
    disabled_rule_group = optional(list(object({
      rule_group_name = string
      rules           = list(string)
    })), [])
    file_upload_limit_in_mb     = optional(number, null)
    request_body_check          = optional(bool, true)
    max_request_body_size_in_kb = optional(number, null)
    exclusions = optional(list(object({
      match_variable          = string
      selector_match_operator = optional(string, null)
      selector                = optional(string, null)
    })), [])
  })
  default     = {}
  description = ""
  # waf_configuration = { enabled = "", firewall_mode = "", rule_set_version = ""}
}

variable "frontend_ip_configurations" {
  type = list(object({
    name                          = string
    private_ip_address_allocation = optional(string, "Dynamic")
    private_ip_address            = optional(string, null)
    ip_version                    = optional(string, "IPv4")
    subnet_id                     = optional(bool, null)
    is_public                     = optional(bool, false)
    domain_name                   = optional(string, null)
  }))
}


variable "backend_address_pools" {
  type        = list(string)
  description = "List of objects that represent the configuration of each backend address pool."
  # backend_address_pools = [{ name = "", ip_addresses = "" }]
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

variable "ssl_certificates" {
  type = list(object({
    name                = string
    data                = string
    password            = string
    key_vault_secret_id = string
  }))
  default     = []
  description = "List of objects that represent the configuration of each ssl certificate."
  # ssl_certificates = [{ name = "", data = "", password = "", key_vault_secret_id = "" }]
}

variable "http_listeners" {
  type = list(object({
    name                      = string
    frontend_ip_configuration = string
    port                      = number
    protocol                  = string
    host_name                 = string
    ssl_certificate_name      = optional(string, null)
  }))
  description = "List of objects that represent the configuration of each http listener."
  # http_listeners = [{ name = "", frontend_ip_configuration = "", port = "", protocol = "", host_name = "", ssl_certificate_name = "" }]
}


variable "probes" {
  type = list(object({
    name                = string
    host                = string
    protocol            = string
    path                = string
    interval            = optional(number, 5)
    timeout             = optional(number, 5)
    unhealthy_threshold = optional(number, 5)
  }))
  default     = []
  description = "List of objects that represent the configuration of each probe."
  # probes = [{ name = "", host = "", protocol = "", path = "", interval = "", timeout = "", unhealthy_threshold = "" }]
}


variable "backend_http_settings" {
  type = list(object({
    name            = string
    port            = number
    protocol        = string
    request_timeout = number
    host_name       = string
    probe_name      = string
  }))
  description = "List of objects that represent the configuration of each backend http settings."
  # backend_http_settings = [{ name = "", port = "", protocol = "", request_timeout = "", host_name = "", probe_name = "" }]
}


variable "request_routing_rules" {
  type = list(object({
    name                       = string
    http_listener_name         = string
    backend_address_pool_name  = string
    backend_http_settings_name = string
  }))
  description = "List of objects that represent the configuration of each backend request routing rule."
  # request_routing_rules = [{ name = "", http_listener_name = "", backend_address_pool_name = "", backend_http_settings_name = "" }]
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

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to set on the resources."
}


variable "zones" {
  type     = list(string)
  default  = ["1", "2", "3"]
  nullable = false
}