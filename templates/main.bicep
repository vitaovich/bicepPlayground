@description('my user object id')
param myObjId string

@description('Location for resources.')
param location string = resourceGroup().location


@description('storage account name')
param accountName string = '${uniqueString(resourceGroup().id)}models'

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

var containers = [
  {
    name: 'original'
  }
  {
    name: 'modified'
  }
]

resource symbolicname 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for container in containers: {
    name: '${storageAccount.name}/default/${container.name}-${uniqueString(resourceGroup().id)}'
  }
]

@description('This is the built-in Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: storageAccount
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, myObjId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: myObjId
    principalType: 'Group'
  }
}

module azfunc 'azfunc.bicep' = {
  name: 'AzFunc'
  params: {
    appInsightsLocation: location
    location: location
  }
}
