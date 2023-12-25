@description('my user object id')
param myObjId string

@description('The prefix name of the function app that you wish to create.')
param appNamePrefix string = 'myfnapp'

@description('The name of the function app that you wish to create.')
param appName string = '${appNamePrefix}${uniqueString(resourceGroup().id)}'

@description('Provide a name for the system topic.')
param storageAccountTopicName string = 'mystoragesystemtopic'

var functionName = 'myBlobEventToCosmosTrigger'

resource azfunc 'Microsoft.Web/sites@2021-03-01' existing = {
  name: appName
}

resource myEventfunction 'Microsoft.Web/sites/functions@2021-03-01' existing = {
  name:functionName
  parent:azfunc
}

module azFuncEventSubscription './event.subscription.bicep' = {
  name: 'az-func-event-subscription'
  params:{
    eventSubName: 'subToStorage'
    includedEventTypes: [
      'Microsoft.Storage.BlobCreated'
      'Microsoft.Storage.BlobDeleted'
    ]
    systemTopicName: storageAccountTopicName
    endpointType: 'AzureFunction'
    functionId: myEventfunction.id
  }
}
