# Global Setup for the Terreform enviorment
terraform {
  required_providers {
    # Add the Azue Terraform module
    azurerm = {
      source  = "hashicorp/azurerm",
      version = "~> 3.71.0"
    }
  }
}

# Setup the Azure Module
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Create our Ressourcegroup, where we will deploy our enviorment!
resource "azurerm_resource_group" "noerkelit_school" {
  name     = "noerkelit"
  location = var.azure_location
}
