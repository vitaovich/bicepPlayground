@description('storage account name')
param accountName string = '${uniqueString(resourceGroup().id)}models'

@description('Location for resources.')
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: accountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

@description('The container names to create')
param containerInfos array

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for containerName in containerInfos: {
    parent: blobService
    name: '${containerName}-${uniqueString(resourceGroup().id)}'
  }
]

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageEndPoint string = storageAccount.properties.primaryEndpoints.blob
