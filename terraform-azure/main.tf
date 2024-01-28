# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    "Environment" = "Dev",
    "Team"        = "vitaovich"
  }
}

resource "azurerm_storage_account" "models" {
  name                     = "${substr(sha256(azurerm_resource_group.rg.name),0,13)}models"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Environment" = "Dev",
    "Team"        = "vitaovich"
  }
}

resource "azurerm_storage_container" "modified" {
  name                  = "modified-${substr(sha256(azurerm_resource_group.rg.name),0,13)}"
  storage_account_name  = azurerm_storage_account.models.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "original" {
  name                  = "original-${substr(sha256(azurerm_resource_group.rg.name),0,13)}"
  storage_account_name  = azurerm_storage_account.models.name
  container_access_type = "private"
}

resource "azurerm_storage_account" "azfunc" {
  name                     = "${substr(sha256(azurerm_resource_group.rg.name),0,13)}azfunc"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Environment" = "Dev",
    "Team"        = "vitaovich"
  }
}

resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.models.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "22a14f43-816f-4fc8-8b17-08b3769ce9de"
}