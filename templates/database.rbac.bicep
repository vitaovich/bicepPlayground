
@description('The Service Principal ID')
param principalId string

@description('The name of the storage of the web app.')
param databaseAccountName string

@description('The name of the storage of the web app.')
param roleDefinitionName string


resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' existing = {
  name: databaseAccountName
}

resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-04-15' existing = {
  name: roleDefinitionName
  parent: databaseAccount
}

var roleAssignmentId = guid(sqlRoleDefinition.id, principalId, databaseAccount.id)

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: roleAssignmentId
  parent: databaseAccount
  properties:{
    roleDefinitionId: sqlRoleDefinition.id
    principalId: principalId
    scope: databaseAccount.id
  }
}
