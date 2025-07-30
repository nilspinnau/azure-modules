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

variable "tags" {
  type    = map(string)
  default = {}
}

variable "service_plan_id" {

}

variable "public_network_access_enabled" {
  type        = bool
  description = "Whether public network access is enabled for the Function App."
  default     = false
}

variable "webdeploy_publish_basic_authentication_enabled" {
  type        = bool
  description = "Enable basic authentication for Web Deploy."
  default     = false
}

variable "ftp_publish_basic_authentication_enabled" {
  type        = bool
  description = "Enable FTP publish basic authentication."
  default     = false
}

variable "auth_settings_v2" {
  type = object({
    auth_enabled           = optional(bool, false)
    require_authentication = optional(bool, false)
    require_https          = optional(bool, true)
    active_directory = optional(object({
    }), {})
    google = optional(object({
    }), {})
    microsoft = optional(object({
    }), {})
    facebook = optional(object({
    }), {})
  })
  default = {}
}

variable "os_type" {
  type        = string
  description = "The OS type of the App Service Plan."
  default     = "Linux"
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "site_config" {
  type = object({
    always_on          = optional(bool, true)
    ftps_state         = optional(string, "AllAllowed")
    min_tls_version    = optional(string, "1.2")
    http2_enabled      = optional(bool, true)
    linux_fx_version   = optional(string, null)
    windows_fx_version = optional(string, null)
    app_command_line   = optional(string, null)
    application_stack = optional(object({
      powershell_core_version = optional(string, "7.4")
      dotnet_version          = optional(string, null)
      node_version            = optional(string, null)
      python_version          = optional(string, null)
      java_version            = optional(string, null)
    }), {})
  })
  default = {}
}

variable "app_settings" {
  type        = map(string)
  description = "Application settings for the Function App."
  default     = {}
}

variable "storage_account" {
  type = object({
    name       = string
    id         = string
    access_key = optional(string, null)
  })
}

variable "functions" {
  type = map(object({
    name = string
    files = optional(map(object({
      content = optional(string, "")
      path    = optional(string, "")
    })), {})
    language    = optional(string, "PowerShell")
    config_json = optional(string, null)
    enabled     = optional(bool, true)
  }))
  default = {}
}
