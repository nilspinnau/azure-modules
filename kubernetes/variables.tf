variable "location" {
  description = "The Azure region where the AKS cluster will be created"
  type        = string
}

variable "resource_suffix" {
  description = "Suffix to append to the resource names"
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group where the AKS cluster will be created"
  type        = string
}

variable "node_resource_group_name" {
  description = "The name of the resource group where the AKS nodes will be created"
  type        = string
  default     = ""
  nullable    = false
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

# Kubernetes configuration
variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
  default     = null # Will use the default version provided by Azure
}

variable "sku_tier" {
  description = "The SKU Tier of the AKS cluster. Possible values: Free or Standard"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "The sku_tier must be one of 'Free' or 'Standard'."
  }
}

variable "default_node" {
  type = object({
    name    = optional(string, "ctrlnode")
    vm_size = optional(string, "Standard_B2s_v2")

    subnet_id = optional(string, null)

    auto_scaling_enabled = optional(bool, true)
    node_count           = optional(number, 1)
    min_count            = optional(number, 1)
    max_count            = optional(number, 1000)
    max_pods             = optional(number, 50)

    node_labels = optional(map(string), {})

    os_disk_size_gb = optional(number, 128)
    os_type         = optional(string, "Linux")
    os_sku          = optional(string, "AzureLinux")
  })
  nullable = false
}

# Additional node pools
variable "additional_node_pools" {
  description = "Map of additional node pools to create"
  type = map(object({
    subnet_id     = string
    pod_subnet_id = optional(string, null)

    vm_size = optional(string, "Standard_B2s_v2")

    auto_scaling_enabled = optional(bool, true)
    node_count           = optional(number, 1)
    min_count            = optional(number, 1)
    max_count            = optional(number, 1000)
    max_pods             = optional(number, 50)

    node_labels = optional(map(string), {})
    node_taints = optional(set(string), [])

    priority        = optional(string, "Regular")
    spot_max_price  = optional(number, null)
    eviction_policy = optional(string, "Delete")

    proximity_placement_group_id = optional(string, null)
    ultra_ssd_enabled            = optional(bool, false)

    os_type         = optional(string, "Linux")
    os_sku          = optional(string, "AzureLinux")
    os_disk_type    = optional(string, "Managed")
    os_disk_size_gb = optional(number, null)

    workload_runtime = optional(string, "OCIContainer")
    scale_down_mode  = optional(string, "Delete")

    network_profile = optional(object({
      allowed_host_ports = optional(list(object({
        port_start = number
        port_end   = number
        protocol   = string
      })), [])
      application_security_group_ids = optional(set(string), [])
    }), {})
  }))
  default = {}
}

variable "network_profile" {
  description = "Network profile for the AKS cluster"
  type = object({
    network_plugin      = optional(string, "azure")
    network_plugin_mode = optional(string, "overlay")
    network_data_plane  = optional(string, "azure")
    network_policy      = optional(string, "calico")

    dns_service_ip = optional(string, null)
    pod_cidrs      = optional(set(string), null)
    service_cidrs  = optional(set(string), null)
    ip_versions    = optional(set(string), ["IPv4"])

    outbound_type     = optional(string, "userDefinedRouting")
    load_balancer_sku = optional(string, "standard")
    load_balancer_profile = optional(object({
      managed_outbound_ip_count   = optional(number, null)
      outbound_ip_prefix_ids      = optional(set(string), [])
      outbound_ip_address_ids     = optional(set(string), [])
      idle_timeout_in_minutes     = optional(number, 30)
      managed_outbound_ipv6_count = optional(number, null)
    }), {})
    nat_gateway_profile = optional(object({
      idle_timeout_in_minutes   = optional(number, 4)
      managed_outbound_ip_count = optional(number, 1)
    }), {})
  })
  default = {}

}

variable "host_encryption_enabled" {
  type    = bool
  default = false
}

variable "auto_scaler_profile" {
  description = "Profile for the cluster autoscaler"
  type = object({
    balance_similar_node_groups      = optional(bool, null)
    expander                         = optional(string, null)
    max_graceful_termination_sec     = optional(string, null)
    max_node_provisioning_time       = optional(string, null)
    max_unready_nodes                = optional(number, null)
    max_unready_percentage           = optional(number, null)
    new_pod_scale_up_delay           = optional(string, null)
    scale_down_delay_after_add       = optional(string, null)
    scale_down_delay_after_delete    = optional(string, null)
    scale_down_delay_after_failure   = optional(string, null)
    scan_interval                    = optional(string, null)
    scale_down_unneeded              = optional(string, null)
    scale_down_unready               = optional(string, null)
    scale_down_utilization_threshold = optional(string, null)
    empty_bulk_delete_max            = optional(string, null)
    skip_nodes_with_local_storage    = optional(bool, null)
    skip_nodes_with_system_pods      = optional(bool, null)
  })
  default = {}
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs (required when identity_type is UserAssigned)"
  type        = set(string)
  default     = []
}

variable "container_registry_id" {
  type    = string
  default = null
}


variable "admin_group_object_ids" {
  description = "Object IDs of AAD groups with admin access"
  type        = set(string)
  default     = []
}

variable "azure_monitor_workspace_id" {
  type    = string
  default = null
}

# Availability zones
variable "zones" {
  description = "List of availability zones to use for nodes"
  type        = set(string)
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to the AKS cluster"
  type        = map(string)
  default     = {}
}

# # Private cluster configuration
# variable "private_cluster_enabled" {
#   description = "Enables private cluster, which makes the API server only accessible from within the virtual network"
#   type        = bool
#   default     = true
# }

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone for the private cluster. Options: 'System', 'None', or resource ID of the private DNS zone"
  type        = string
  nullable    = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "admin_username" {
  type    = string
  default = "azkubeadmin"
}

variable "maintenance_window" {
  type = object({
    allowed = optional(set(object({
      day   = string
      hours = set(number)
    })), [])
    not_allowed = optional(set(object({
      start = string
      end   = string
    })), [])
  })
  default = null
}

variable "ingress_application_gateway" {
  type = object({
    gateway_id   = string
    gateway_name = string
    subnet_id    = string
  })
  nullable = true
  default  = null
}

variable "key_vault_secrets_provider" {
  type = object({
    secret_rotation_enabled  = optional(bool, true)
    secret_rotation_interval = optional(string, null)
  })
  nullable = true
  default  = null
}

variable "key_management_service" {
  type = object({
    key_vault_key_id         = string
    key_vault_network_access = optional(string, null)
  })
  default = null
}

variable "api_server_authorized_ip_ranges" {
  description = "List of IP ranges authorized to access the Kubernetes API server"
  type        = set(string)
  default     = null
}

# Security and encryption
variable "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set which should be used for the Nodes and Volumes"
  type        = string
  default     = null
}
