@description('Cosmos DB account name')
param accountName string = 'cosmos-${uniqueString(resourceGroup().id)}'

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The name for the SQL API database')
param databaseName string

// @description('The name for the SQL API container')
// param containerName string

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: toLower(accountName)
  location: location
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: account
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
    options: {
      throughput: 500
    }
  }
}

var containersInfo = [
  {
    name: 'upload'
  }
  {
    name: 'processed'
  }
  {
    name: 'leases'
  }
]

resource containers 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = [for container in containersInfo: {
    parent: database
    name: container.name
    properties: {
      resource: {
        id: container.name
        partitionKey: {
          paths: [
            '/id'
          ]
          kind: 'Hash'
        }
        indexingPolicy: {
          indexingMode: 'consistent'
          includedPaths: [
            {
              path: '/*'
            }
          ]
          excludedPaths: [
            {
              path: '/_etag/?'
            }
          ]
        }
      }
    }
  }
]
