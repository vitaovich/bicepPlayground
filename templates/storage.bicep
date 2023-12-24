@description('storage account name')
param accountName string = '${uniqueString(resourceGroup().id)}models'

@description('Location for resources.')
param location string = resourceGroup().location

@description('my user object id')
param myObjId string

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

var containerInfo = [
  {
    name: 'original'
  }
  {
    name: 'modified'
  }
]

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = [for container in containerInfo: {
    parent: blobService
    name: '${container.name}-${uniqueString(resourceGroup().id)}'
  }
]

@description('This is the built-in Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: storageAccount
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: blobService
  name: guid(storageAccount.id, myObjId, contributorRoleDefinition.id)
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: myObjId
    principalType: 'Group'
  }
}

// @description('Provide a name for the Event Grid subscription.')
// param eventSubName string = 'subToStorage'

// @description('Provide the URL for the WebHook to receive events. Create your own endpoint for events.')
// param endpoint string

@description('Provide a name for the system topic.')
param systemTopicName string = 'mystoragesystemtopic'

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: systemTopicName
  location: location
  properties: {
    source: storageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

// resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2021-12-01' = {
//   parent: systemTopic
//   name: eventSubName
//   properties: {
//     destination: {
//       properties: {
//         endpointUrl: endpoint
//       }
//       endpointType: 'WebHook'
//     }
//     filter: {
//       includedEventTypes: [
//         'Microsoft.Storage.BlobCreated'
//         'Microsoft.Storage.BlobDeleted'
//       ]
//     }
//   }
// }
