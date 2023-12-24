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

module mainStorage 'storage.bicep' = {
  name: 'az-storage'
  params: {
    location: location
    containerInfos: [
      'original'
      'modified'
    ]
  }
}

module mainStorageRBAC './storage.rbac.bicep' = {
  dependsOn:[
    mainStorage
  ]
  name: 'az-storage-rbac'
  params:{
    storageAccountName: mainStorage.outputs.storageAccountName
    principalId: myObjId
    principalType: 'Group'
    roleIds: ['ba92f5b4-2d11-453d-a403-e96b0029c9fe']
  }
}

module database 'database.bicep' = {
  name: 'az-cosmosdb'
  params: {
    location: location
    databaseName: 'Models'
  }
}

module databaseRoleDefinition 'database.roleDef.bicep' = {
  dependsOn:[
    database
  ]
  name: 'az-cosmosdb-roleDefinition'
  params: {
    dataActions: [
      'Microsoft.DocumentDB/databaseAccounts/readMetadata'
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
      'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
    ]
    databaseAccountName: database.outputs.cosmosDbAccountName
    principalId: myObjId
    roleDefinitionName: 'My Read Write Role'
  }
}

module databaseRBAC './database.rbac.bicep' = {
  dependsOn:[
    databaseRoleDefinition
  ]
  name: 'az-cosmosdb-rbac'
  params:{
    databaseAccountName: database.outputs.cosmosDbAccountName
    principalId: myObjId
    roleDefinitionName: databaseRoleDefinition.outputs.readWriteRoleDefinitionName
  }
}
