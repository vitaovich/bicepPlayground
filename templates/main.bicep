@description('my user object id')
param myObjId string

@description('Location for resources.')
param location string = resourceGroup().location

@description('Provide a name for the system topic.')
param storageAccountTopicName string = 'mystoragesystemtopic'

@description('The prefix name of the function app that you wish to create.')
param appNamePrefix string = 'myfnapp'

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

module azfunc 'azfunc.bicep' = {
  dependsOn: [
    azStorage
    azCosmosDB
  ]
  name: 'az-func'
  params: {
    appNamePrefix: appNamePrefix
    appInsightsLocation: location
    location: location
    myCosmosEndpoint: azCosmosDB.outputs.cosmosDbEndpoint
    myStorageEndpoint: azStorage.outputs.storageEndPoint
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
    systemTopicName: storageAccountTopicName
  }
}
