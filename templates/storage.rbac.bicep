@description('The name of the storage of the web app.')
param storageAccountName string

@description('The Service Principal ID')
param principalId string

@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
@description('The Service Principal type')
param principalType string

@description('The built in role GUID. See https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
param roleIds array

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

@description('These are the built-in roles. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
resource roleDefinitions 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = [for roleId in roleIds: {
    scope: storageAccount
    name: roleId
  }
]

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(roleIds)): {
    scope: storageAccount
    name: guid(storageAccount.id, principalId, roleDefinitions[i].id)
    properties: {
      roleDefinitionId: roleDefinitions[i].id
      principalId: principalId
      principalType: principalType
    }
  }
]
