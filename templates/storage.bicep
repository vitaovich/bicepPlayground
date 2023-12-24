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

// @description('Provide a name for the Event Grid subscription.')
// param eventSubName string = 'subToStorage'

// @description('Provide the URL for the WebHook to receive events. Create your own endpoint for events.')
// param endpoint string

// @description('Provide a name for the system topic.')
// param systemTopicName string = 'mystoragesystemtopic'

// resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
//   name: systemTopicName
//   location: location
//   properties: {
//     source: storageAccount.id
//     topicType: 'Microsoft.Storage.StorageAccounts'
//   }
// }

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
