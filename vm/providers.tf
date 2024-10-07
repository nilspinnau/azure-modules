terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.100.0"
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