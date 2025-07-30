terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.35, <= 5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.10.0"
    }
  }
}