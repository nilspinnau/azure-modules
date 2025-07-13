


resource "azurerm_function_app_function" "default" {
  for_each = var.functions

  name            = each.key
  function_app_id = local.function_app.id

  language = each.value.language

  config_json = each.value.config_json

  enabled = each.value.enabled

  dynamic "file" {
    for_each = each.value.files
    content {
      name    = file.key
      content = file.value.content != "" ? file.value.content : file(file.value.path)
    }
  }
}