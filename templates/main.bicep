@description('my user object id')
param myObjId string

@description('Location for resources.')
param location string = resourceGroup().location

module azfunc 'azfunc.bicep' = {
  name: 'AzFunc'
  params: {
    // principalId: myObjId
    // principalType: 'Group'
    appInsightsLocation: location
    location: location
  }
}

module mainStorage 'storage.bicep' = {
  name: 'Storage'
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
  name: 'main-storage-rbac'
  params:{
    storageAccountName: mainStorage.outputs.storageAccountName
    principalId: myObjId
    principalType: 'Group'
    roleIds: ['ba92f5b4-2d11-453d-a403-e96b0029c9fe']
  }
}

module database 'database.bicep' = {
  name: 'Database'
  params: {
    location: location
    databaseName: 'Models'
    myObjId: myObjId
  }
}
