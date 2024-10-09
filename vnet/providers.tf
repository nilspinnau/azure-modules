terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=3.110.0"
    }
    azapi = {
      source = "azure/azapi"
      version = ">=1.14.0"
    }
  }
}