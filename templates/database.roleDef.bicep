@description('The Service Principal ID')
param principalId string

@description('Friendly name for the SQL Role Definition')
param roleDefinitionName string

@description('Data actions permitted by the Role Definition')
param dataActions array

@description('The name of the storage of the web app.')
param databaseAccountName string

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: databaseAccountName
}

var roleDefinitionId = guid('sql-role-definition-', principalId, databaseAccount.id)

resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-04-15' = {
  parent: databaseAccount
  name: roleDefinitionId
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      databaseAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ]
  }
}

output readWriteRoleDefinitionName string = sqlRoleDefinition.name
