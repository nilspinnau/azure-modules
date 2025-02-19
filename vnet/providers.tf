terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.13"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.14.0"
    }
  }
}
