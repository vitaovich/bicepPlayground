@description('my user object id')
param myObjId string

@description('Location for resources.')
param location string = resourceGroup().location

module azfunc 'azfunc.bicep' = {
  name: 'az-func'
  params: {
    appInsightsLocation: location
    location: location
  }
}

module azStorage 'storage.bicep' = {
  name: 'az-storage'
  params: {
    location: location
    containerInfos: [
      'original'
      'modified'
    ]
  }
}

module azStorageRBAC './storage.rbac.bicep' = {
  dependsOn:[
    azStorage
  ]
  name: 'az-storage-rbac'
  params:{
    storageAccountName: azStorage.outputs.storageAccountName
    principalId: myObjId
    principalType: 'Group'
    roleIds: ['ba92f5b4-2d11-453d-a403-e96b0029c9fe']
  }
}

module azFuncStorageRBAC './storage.rbac.bicep' = {
  dependsOn:[
    azStorage
  ]
  name: 'az-func-storage-rbac'
  params:{
    storageAccountName: azStorage.outputs.storageAccountName
    principalId: azfunc.outputs.principalId
    principalType: 'ServicePrincipal'
    roleIds: ['ba92f5b4-2d11-453d-a403-e96b0029c9fe']
  }
}

module azCosmosDB 'database.bicep' = {
  name: 'az-cosmosdb'
  params: {
    location: location
    databaseName: 'Models'
  }
}

module databaseRoleDefinition 'database.roleDef.bicep' = {
  dependsOn:[
    azCosmosDB
  ]
  name: 'az-cosmosdb-roleDefinition'
  params: {
    dataActions: [
      'Microsoft.DocumentDB/databaseAccounts/readMetadata'
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
    ]
    databaseAccountName: azCosmosDB.outputs.cosmosDbAccountName
    principalId: myObjId
    roleDefinitionName: 'My Read Write Role'
  }
}

module userGroupCosmosdbRBAC './database.rbac.bicep' = {
  dependsOn:[
    databaseRoleDefinition
  ]
  name: 'az-cosmosdb-rbac'
  params:{
    databaseAccountName: azCosmosDB.outputs.cosmosDbAccountName
    principalId: myObjId
    roleDefinitionName: databaseRoleDefinition.outputs.readWriteRoleDefinitionName
  }
}

module azFuncCosmosdbRBAC './database.rbac.bicep' = {
  dependsOn:[
    databaseRoleDefinition
  ]
  name: 'az-func-cosmosdb-rbac'
  params:{
    databaseAccountName: azCosmosDB.outputs.cosmosDbAccountName
    principalId: azfunc.outputs.principalId
    roleDefinitionName: databaseRoleDefinition.outputs.readWriteRoleDefinitionName
  }
}

module azStorageSystemTopic './event.topic.bicep' = {
  dependsOn:[
    azStorage
  ]
  name: 'az-storage-system-topic'
  params:{
    sourceId: azStorage.outputs.storageAccountId
    topicType: 'Microsoft.Storage.StorageAccounts'
    location: location
  }
}

module azFuncEventSubscription './event.subscription.bicep' = {
  dependsOn:[
    azfunc
    azStorageSystemTopic
  ]
  name: 'az-func-event-subscription'
  params:{
    eventSubName: 'subToStorage'
    includedEventTypes: [
      'Microsoft.Storage.BlobCreated'
      'Microsoft.Storage.BlobDeleted'
    ]
    systemTopicName: azStorageSystemTopic.outputs.systemTopicName
    endpointType: 'AzureFunction'
    functionId: azfunc.outputs.myEventfunctionId
  }
}
