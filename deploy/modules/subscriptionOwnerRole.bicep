@description('PrincipalIds of the Identities')
param identityPrincipalId string = ''

param identityPrincipalIds array = [identityPrincipalId]

targetScope = 'subscription'


@description('This is the built-in Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner')
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

resource ownerRoleAssignement 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for identityId in identityPrincipalIds: {
  name: guid(subscription().id, identityId, ownerRoleDefinition.id)
  properties: {
    principalId: identityId
    roleDefinitionId: ownerRoleDefinition.id
  }
}]
