terraform {
  required_version = ">=1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.5.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.10.0"
    }
  }
}
