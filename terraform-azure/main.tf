# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.89.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

locals {
  prefix = "${substr(sha256(var.resource_group_name),0,13)}"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    "Environment" = "Dev",
    "Team"        = "vitaovich"
  }
}

################################
# Storage Account
################################
resource "azurerm_storage_account" "models" {
  name                     = "${local.prefix}models"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    "Environment" = "Dev",
    "Team"        = "vitaovich"
  }
}

variable "container_instance_names" {
  description = "List of container names"
  type        = list(string)
  default     = ["modified", "initialprocess", "original"]
}

resource "azurerm_storage_container" "model_containers" {
  for_each = toset(var.container_instance_names)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.models.name
  container_access_type = "private"
}

variable "queue_instance_names" {
  description = "List of queue names"
  type        = list(string)
  default     = ["test1", "test2"]
}

resource "azurerm_storage_queue" "model_queues" {
  for_each = toset(var.queue_instance_names)

  name                  = each.value
  storage_account_name  = azurerm_storage_account.models.name
}

resource "azurerm_storage_account" "azfunc" {
  name                     = "${local.prefix}azfunc"
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
  name                = "${local.prefix}myserviceplan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

resource "azurerm_linux_function_app" "example" {
  name                = "${local.prefix}myfnapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.azfunc.name
  storage_account_access_key = azurerm_storage_account.azfunc.primary_access_key
  service_plan_id            = azurerm_service_plan.example.id

  app_settings = {
    "my_storage__serviceUri" = azurerm_storage_account.models.primary_blob_endpoint
    "my_storage__queueServiceUri" = azurerm_storage_account.models.primary_queue_endpoint
    "my_cosmos_accountEndpoint" = azurerm_cosmosdb_account.db.endpoint
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_key = azurerm_application_insights.example.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.example.connection_string
    application_stack {
      python_version = 3.11
    }
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
  }
  https_only = true
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "${local.prefix}loganalytics"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "example" {
  name                = "${local.prefix}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.example.id
  application_type    = "web"
}

variable "contributor_role_names" {
  description = "List of container names"
  type        = list(string)
  default     = ["Storage Blob Data Contributor", "Storage Queue Data Contributor", "Storage Queue Data Message Sender"]
}

resource "azurerm_role_assignment" "storage_contributor" {
  for_each = toset(var.contributor_role_names)

  scope                = azurerm_storage_account.models.id
  role_definition_name = each.value
  principal_id         = "22a14f43-816f-4fc8-8b17-08b3769ce9de"
}

resource "azurerm_role_assignment" "az_func_storage_contributor" {
  for_each = toset(var.contributor_role_names)

  scope                = azurerm_storage_account.models.id
  role_definition_name = each.value
  principal_id         = azurerm_linux_function_app.example.identity.0.principal_id
}

################################
# CosmosDB
################################
resource "azurerm_cosmosdb_account" "db" {
  name                = "${local.prefix}-tfex-cosmos-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  enable_free_tier = true

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "westus3"
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = "cosmosdb-sqldb"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  throughput          = 800
}

resource "azurerm_cosmosdb_sql_container" "my_sql_container" {
  name                  = "container"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/id"
  partition_key_version = 1

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "leases_container" {
  name                  = "leases"
  resource_group_name   = azurerm_resource_group.rg.name
  account_name          = azurerm_cosmosdb_account.db.name
  database_name         = azurerm_cosmosdb_sql_database.main.name
  partition_key_path    = "/id"
}

resource "azurerm_cosmosdb_sql_role_definition" "example" {
  name                = "My Read Write Role"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  type                = "CustomRole"
  assignable_scopes   = [azurerm_cosmosdb_account.db.id]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "role_assign_contributor_group" {
  name                = "${uuidv5("dns", "${azurerm_cosmosdb_sql_role_definition.example.id}${"22a14f43-816f-4fc8-8b17-08b3769ce9de"}${azurerm_cosmosdb_sql_database.main.id}")}"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.example.id
  principal_id        = "22a14f43-816f-4fc8-8b17-08b3769ce9de"
  scope               = azurerm_cosmosdb_account.db.id
}

resource "azurerm_cosmosdb_sql_role_assignment" "role_assign_az_func" {
  name                = "${uuidv5("dns", "${azurerm_cosmosdb_sql_role_definition.example.id}${azurerm_linux_function_app.example.identity.0.principal_id}${azurerm_cosmosdb_sql_database.main.id}")}"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.example.id
  principal_id        = azurerm_linux_function_app.example.identity.0.principal_id
  scope               = azurerm_cosmosdb_account.db.id
}