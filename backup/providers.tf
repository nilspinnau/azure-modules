terraform {
  required_version = ">=1.3.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.6.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.10.0"
    }
  }
}