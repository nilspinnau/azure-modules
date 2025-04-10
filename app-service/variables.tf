variable "location" {
  type        = string
  description = "Determines in which Azure region the resources should be deployed in."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to deploy the VMs."
}


variable "resource_suffix" {
  type        = string
  description = "Suffix for all resources which will be deployed."
}

variable "zone_redundant" {
  type        = bool
  description = "Should be zone redundant."
  default     = true
}

variable "service_plan" {
  type = object({
    os_type                      = optional(string, "Linux")
    maximum_elastic_worker_count = optional(number, 100)
    sku                          = optional(string, "EP1")
    worker_count                 = optional(number, 1)
    environment = optional(object({
      virtual_network_id           = string
      address_prefix               = string
      subnet_id                    = string
      internal_load_balancing_mode = optional(string, "Web, Publishing")
      cluster_settings             = map(string)
    }), null)
  })

  validation {
    condition     = contains(["B1", "B2", "B3", "D1", "F1", "I1", "I2", "I3", "I1v2", "I2v2", "I3v2", "I4v2", "I5v2", "I6v2", "P1v2", "P2v2", "P3v2", "P0v3", "P1v3", "P2v3", "P3v3", "P1mv3", "P2mv3", "P3mv3", "P4mv3", "P5mv3", "S1", "S2", "S3", "SHARED", "EP1", "EP2", "EP3", "FC1", "WS1", "WS2", "WS3", "Y1"], var.service_plan.sku)
    error_message = "value must be a valid SKU"
  }
}


variable "tags" {
  type    = map(string)
  default = {}
}

variable "premium_plan_auto_scale_enabled" {
  type    = bool
  default = false
}