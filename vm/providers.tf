terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">=1.10.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.12.0"
    }
  }
}