
locals {
  account_tier = var.account_kind == "FileStorage" || var.account_kind == "BlockBlobStorage" ? "Premium" : var.account_tier
}

resource "random_string" "storage_account_name" {
  length  = 24 - length(var.name)
  upper   = false
  special = false
}

locals {
  # soft delete is enabled per default when storage kind is any kind other than BlobStorage
  enable_restore_policy = var.account_kind == "StorageV2" && var.account_tier == "Standard" && var.enable_versioning && var.enable_change_feed && var.enable_point_in_time_restore

  sta_name = "${var.name}${random_string.storage_account_name.result}"
}

# https://github.com/hashicorp/terraform-provider-azurerm/issues/10872
# https://github.com/hashicorp/terraform-provider-azurerm/issues/24489
# https://github.com/hashicorp/terraform-provider-azurerm/issues/13070
resource "azurerm_storage_account" "default" {
  name                = local.sta_name
  resource_group_name = var.resource_group_name

  location                 = var.location
  account_kind             = var.account_kind
  account_tier             = local.account_tier
  account_replication_type = var.account_replication_type

  local_user_enabled = false

  access_tier = var.account_kind != "BlockBlobStorage" ? var.access_tier : null

  default_to_oauth_authentication = true
  shared_access_key_enabled       = var.enable_sas_key

  public_network_access_enabled   = var.public_access.enabled
  allow_nested_items_to_be_public = false

  cross_tenant_replication_enabled  = false
  infrastructure_encryption_enabled = var.account_kind == "StorageV2" || (local.account_tier == "Premium" && (var.account_kind == "FileStorage" || var.account_kind == "BlockBlobStorage")) ? true : false


  large_file_share_enabled = false

  # we have soft delete enabled thus this cannot be enabled
  is_hns_enabled = var.data_lake_gen_2.enabled
  sftp_enabled   = var.data_lake_gen_2.enabled ? var.data_lake_gen_2.sftp_enabled : false

  nfsv3_enabled = var.data_lake_gen_2.enabled ? var.data_lake_gen_2.nfsv3_enabled : false


  https_traffic_only_enabled = true
  min_tls_version            = var.min_tls_version

  identity {
    type = "SystemAssigned"
  }

  dynamic "blob_properties" {
    for_each = var.account_kind != "FileStorage" ? [1] : []
    content {
      dynamic "delete_retention_policy" {
        for_each = var.account_kind != "BlobStorage" && var.blob_soft_delete_retention_days != null ? [1] : []
        content {
          days = var.blob_soft_delete_retention_days
        }
      }
      dynamic "container_delete_retention_policy" {
        for_each = var.account_kind != "BlobStorage" && var.container_soft_delete_retention_days != null ? [1] : []
        content {
          days = var.container_soft_delete_retention_days
        }
      }
      dynamic "restore_policy" {
        for_each = local.enable_restore_policy && var.blob_soft_delete_retention_days != null ? [1] : []
        content {
          days = var.blob_soft_delete_retention_days - 1
        }
      }
      change_feed_retention_in_days = var.enable_change_feed == true ? var.change_feed_retention_in_days : null
      versioning_enabled            = var.account_kind == "BlobStorage" && !var.data_lake_gen_2.enabled ? null : var.enable_versioning
      last_access_time_enabled      = var.enable_last_access_time
      change_feed_enabled           = var.enable_change_feed
    }
  }

  dynamic "share_properties" {
    for_each = (var.account_kind == "StorageV2" || var.account_kind == "FileStorage") && var.share_soft_delete_retention_days != null ? [1] : []
    content {
      retention_policy {
        days = var.share_soft_delete_retention_days
      }
    }
  }

  dynamic "network_rules" {
    for_each = var.public_access.network_rules != null ? [1] : []
    content {
      default_action             = "Deny"
      bypass                     = var.public_access.network_rules.bypass
      ip_rules                   = var.public_access.network_rules.ip_rules
      virtual_network_subnet_ids = var.public_access.network_rules.subnet_ids
    }
  }

  tags       = var.tags
  depends_on = [random_string.storage_account_name]
}

# threat protection
resource "azurerm_advanced_threat_protection" "atp" {
  target_resource_id = azurerm_storage_account.default.id
  enabled            = var.enable_advanced_threat_protection

  depends_on = [azurerm_storage_account.default]
}

resource "azapi_resource" "containers" {
  for_each = var.account_kind != "FileStorage" ? toset(var.containers_list) : []

  name      = lower(each.value)
  parent_id = "${azurerm_storage_account.default.id}/blobServices/default"
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01"
  body = {
    properties = {
      publicAccess = "None"
    }
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.default]
}


locals {
  # quota of fileshare has to be in range between 100 - 102400
  file_shares_quota_min_fixed = [for fileshare in var.file_shares : fileshare.quota < 100 ? { name : fileshare.name, quota : 100 } : { name : fileshare.name, quota : fileshare.quota }]
  file_share_quota_max_fixed  = [for fileshare in local.file_shares_quota_min_fixed : fileshare.quota > 102400 ? { name : fileshare.name, quota : 102400 } : { name : fileshare.name, quota : fileshare.quota }]
  file_share_quota_fixed      = local.file_share_quota_max_fixed
}

resource "azapi_resource" "fileshares" {
  for_each = {
    for k, fileshare in local.file_share_quota_fixed : k => fileshare
    if var.account_kind != "BlobStorage" && var.account_kind != "BlockBlobStorage"
  }

  name      = lower(each.key)
  parent_id = "${azurerm_storage_account.default.id}/fileServices/default"
  type      = "Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01"
  body = {
    properties = {
      metadata   = {}
      shareQuota = each.value.quota < 100 ? 100 : each.value.quota
    }
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.default]
}

resource "azapi_resource" "tables" {
  for_each = var.account_kind == "StorageV2" ? toset(var.tables) : []

  name      = lower(each.value)
  parent_id = "${azurerm_storage_account.default.id}/tableServices/default"
  type      = "Microsoft.Storage/storageAccounts/tableServices/tables@2022-09-01"
  body      = {}

  tags = var.tags

  depends_on = [azurerm_storage_account.default]
}

resource "azapi_resource" "queues" {
  for_each = var.account_kind == "StorageV2" ? toset(var.queues) : []

  name      = lower(each.value)
  parent_id = "${azurerm_storage_account.default.id}/queueServices/default"
  type      = "Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01"
  body = {
    properties = {
      metadata = {}
    }
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.default]
}

resource "azapi_resource" "lifecycle_policy" {
  count = (var.account_kind == "BlobStorage" || var.account_kind == "StorageV2") && length(var.lifecycles) > 0 ? 1 : 0

  type      = "Microsoft.Storage/storageAccounts/managementPolicies@2022-09-01"
  name      = "default"
  parent_id = azurerm_storage_account.default.id
  body = {
    properties = {
      policy = {
        rules = [for idx, rule in var.lifecycles : {
          definition = {
            actions = {
              baseBlob = {
                enableAutoTierToHotFromCool = false
                delete = {
                  daysAfterModificationGreaterThan = rule.delete_after_days
                }
                tierToArchive = var.account_replication_type == "LRS" && rule.tier_to_archive_after_days != null ? {
                  daysAfterModificationGreaterThan = rule.tier_to_archive_after_days
                } : null
                tierToCold = rule.tier_to_cold_after_days != null ? {
                  daysAfterModificationGreaterThan = rule.tier_to_cold_after_days
                } : null
                tierToCool = rule.tier_to_cool_after_days != null ? {
                  daysAfterLastAccessTimeGreaterThan = rule.tier_to_cool_after_days
                } : null
              }
              snapshot = {
                delete = {
                  daysAfterCreationGreaterThan = rule.snapshot_delete_after_days
                }
              }
              version = {
                delete = {
                  daysAfterCreationGreaterThan = rule.version_delete_after_days
                }
              }
            }
            filters = {
              blobTypes = [
                "blockBlob"
              ]
              prefixMatch = rule.prefix_match
            }
          }
          enabled = true
          name    = "rule-${idx}"
          type    = "Lifecycle"
        }]
      }
    }
  }

  tags = var.tags

  depends_on = [azurerm_storage_account.default]
}