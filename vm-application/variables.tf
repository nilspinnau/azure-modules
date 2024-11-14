

variable "location" {
  type = string
}

variable "name" {
  type = string
}


variable "tags" {
  type    = map(any)
  default = {}
}

variable "resource_suffix" {
  type = string
}


variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  type        = string
}


variable "shared_image_gallery_id" {
  type = string
}

variable "supported_os_type" {
  type    = string
  default = "Linux"
}

variable "versions" {
  type = map(object({
    name = string
    target_regions = map(object({
      name                   = string
      regional_replica_count = number
      storage_account_type   = string
    }))
    manage_action = object({
      install = string
      remove  = string
    })
    source = object({
      media_link = string
    })
    config_file         = optional(string, "")
    enable_health_check = optional(bool, false)
    end_of_life_date    = optional(string, "")
    exclude_from_latest = optional(string, "")
    package_file        = optional(string, "")
  }))
}