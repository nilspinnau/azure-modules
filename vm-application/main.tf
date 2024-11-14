


resource "azurerm_gallery_application" "default" {
  name              = "app-${var.name}-${var.resource_suffix}"
  gallery_id        = var.shared_image_gallery_id
  location          = var.location
  supported_os_type = var.supported_os_type
}

resource "azurerm_gallery_application_version" "default" {
  for_each = var.versions

  name                   = each.value.name
  gallery_application_id = azurerm_gallery_application.default.id
  location               = var.location

  manage_action {
    install = each.value.manage_action.install
    remove  = each.value.manage_action.remove
  }

  source {
    media_link = each.value.source.media_link
  }

  target_region {
    name                   = var.location
    regional_replica_count = 1
    storage_account_type   = "Standard_LRS"
  }

  dynamic "target_region" {
    for_each = each.value.replicated_regions
    content {
      name                   = target_region.value.name
      regional_replica_count = target_region.value.regional_replica_count
      storage_account_type   = target_region.value.storage_account_type
    }
  }

  config_file         = each.value.config_file
  enable_health_check = each.value.enable_health_check

  end_of_life_date    = each.value.end_of_life_date
  exclude_from_latest = each.value.exclude_from_latest
  package_file        = each.value.package_file
}