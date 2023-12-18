@description('my user object id')
param myObjId string

@description('Location for resources.')
param location string = resourceGroup().location

module azfunc 'azfunc.bicep' = {
  name: 'AzFunc'
  params: {
    appInsightsLocation: location
    location: location
  }
}

module storage 'storage.bicep' = {
  name: 'Storage'
  params: {
    location: location
    myObjId: myObjId
    // endpoint: 'https://vialekhntesteventgrid.azurewebsites.net/api/updates'
  }
}

module database 'database.bicep' = {
  name: 'Database'
  params: {
    location: location
    databaseName: 'Models'
  }
}
