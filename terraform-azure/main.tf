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

resource "azurerm_service_plan" "example" {
  name                = "${substr(sha256(azurerm_resource_group.rg.name),0,13)}myserviceplan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${substr(sha256(azurerm_resource_group.rg.name),0,13)}myfnapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.azfunc.name
  storage_account_access_key = azurerm_storage_account.azfunc.primary_access_key
  service_plan_id            = azurerm_service_plan.example.id

  app_settings = {
    "my_storage__serviceUri" = azurerm_storage_account.models.primary_blob_endpoint
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
  }
}





resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.models.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "22a14f43-816f-4fc8-8b17-08b3769ce9de"
}

resource "azurerm_role_assignment" "az_func_storage_contributor" {
  scope                = azurerm_storage_account.models.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.example.identity.0.principal_id
}