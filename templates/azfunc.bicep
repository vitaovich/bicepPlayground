@description('The name of the function app that you wish to create.')
param appName string = 'myfnapp${uniqueString(resourceGroup().id)}'

// @description('The Service Principal ID')
// param principalId string

// @allowed([
//   'User'
//   'Group'
//   'ServicePrincipal'
// ])
// @description('The Service Principal type')
// param principalType string

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Location for Application Insights')
param appInsightsLocation string

@description('The language worker runtime to load in the function app.')
@allowed([
  'node'
  'dotnet'
  'java'
  'python'
])
param runtime string = 'python'

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunc'
var functionWorkerRuntime = runtime

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

// module AzureWebJobsStorageRBAC './storage.rbac.bicep' = {
//   name: 'az-func-storage-rbac'
//   params:{
//     storageAccountName: storageAccount.name
//     principalId: principalId
//     principalType: principalType
//     roleIds: [
//       'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner 
//       '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Storage Queue Data Contributor
//       '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
//     ]
//   }
// }

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved:true
  }
  kind: 'functionapp,linux'
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      publicNetworkAccess: 'Enabled'
      linuxFxVersion: 'Python|3.11'
      pythonVersion: '3.11'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
      }
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

var functionNameComputed = 'myBlobEventToCosmosTrigger'

resource myEventfunction 'Microsoft.Web/sites/functions@2021-03-01' = {
  parent: functionApp
  name: functionNameComputed
  properties: {
    config: {
      disabled: false
      bindings: [
      {
          direction: 'IN'
          type: 'eventGridTrigger'
          name: 'event'
      }
      ]
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: appInsightsLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

output principalId string = functionApp.identity.principalId
output myEventfunctionId string = myEventfunction.id
