
output "storage_account_id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.default.id
}

output "storage_account_name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.default.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location."
  value       = azurerm_storage_account.default.primary_blob_endpoint
}

output "storage_account_primary_web_endpoint" {
  description = "The endpoint URL for web storage in the primary location."
  value       = azurerm_storage_account.default.primary_web_endpoint
}

output "storage_account_primary_web_host" {
  description = "The hostname with port if applicable for web storage in the primary location."
  value       = azurerm_storage_account.default.primary_web_host
}

output "storage_primary_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.default.primary_connection_string
  sensitive   = true
}

output "storage_primary_access_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.default.primary_access_key
  sensitive   = true
}

output "storage_secondary_access_key" {
  description = "The primary access key for the storage account."
  value       = azurerm_storage_account.default.secondary_access_key
  sensitive   = true
}

# output "containers" {
#   description = "Map of containers."
#   value = [for container in azurerm_storage_container.containers : {
#     id : container.id
#     name : container.name
#     blob_endpoint : "/${azurerm_storage_account.default.primary_blob_endpoint}${container.name}/"
#   }]
# }

# output "file_shares" {
#   description = "Map of Storage SMB file shares."
#   value       = [for fileshare in azurerm_storage_share.fileshares : fileshare.id]
# }

# output "tables" {
#   description = "Map of Storage SMB file shares."
#   value       = [for table in azurerm_storage_table.tables : table.id]
# }

# output "queues" {
#   description = "Map of Storage SMB file shares."
#   value       = [for queue in azurerm_storage_queue.queues : queue.id]
# }