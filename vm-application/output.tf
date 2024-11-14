

output "gallery_application_id" {
  value = azurerm_gallery_application.default.id
}

output "gallery_application_versions" {
  value = {
    for version in azurerm_gallery_application_version.default : version.name => {
      id                     = version.id
      location               = version.location
      name                   = version.name
      gallery_application_id = version.gallery_application_id
    }
  }
}