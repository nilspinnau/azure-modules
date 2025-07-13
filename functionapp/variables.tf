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
    ftps_state         = optional(string, "Disabled")
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
}

variable "app_settings" {
  type        = map(string)
  description = "Application settings for the Function App."
  default     = {}
}

variable "storage_account" {
  type = object({
    name = string
    id   = string
  })
}
