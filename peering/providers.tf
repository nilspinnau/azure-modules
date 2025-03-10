terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      version               = ">=4.0"
      configuration_aliases = [azurerm.first, azurerm.second]
    }
  }
}