// Azure Deployment Environment
@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

@description('Name of the Devcenter identity')
param identityName string = '${basePrefix}-dc-id'

@description('Name of the Devcenter deployment environment catalog')
param catalogName string = '${basePrefix}-catalog'

param gitHubUrl string
param gitHubBranch string = 'main'
param gitHubPath string

@secure()
@description('PAT for the GitHub repository')
param gitHubPat string = ''

@description('GitHub Repository')
param gitHubAppRepository string

@description('GitHub Branch')
param gitHubAppBranch string

@description('GitHub Owner')
param gitHubAppOwner string

@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project ADE user role')
param projectAdeUserIds array = []

// Read existing resources
resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

module keyVault './keyvault.bicep' = {
  name: '${basePrefix}-keyvault'
  params: {
    basePrefix: basePrefix
    location: location
    gitHubPat: gitHubPat
    identityName: identityName
  }
}

// DevCenter Resources
// Create the catalog
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-04-01' = {
  name: catalogName
  parent: devcenter
  properties: {
    gitHub: {
      uri: gitHubUrl
      branch: gitHubBranch
      path: gitHubPath
      secretIdentifier: keyVault.outputs.secretUri
    }
  }

  dependsOn: [
    keyVault
  ]
}

// Create an environment in DevCenter
resource environment 'Microsoft.DevCenter/devcenters/environmentTypes@2023-04-01' = {
  name: 'dev'
  parent: devcenter
}

// Project Resources
resource adeIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${basePrefix}-ade-id'
  location: location
}

@description('This is the built-in Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner')
#disable-next-line no-unused-existing-resources
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

@description('This is the built-in Contributer role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner')
resource contributerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

@description('This is the built-in Reader role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner')
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var environmentTypeUserRoleAssignments = map(projectAdeUserIds, usr => {
  '${usr}': {
    roles: {
      '${readerRoleDefinition.name}': {}
    }
  }
})

resource projectEnvironment 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' = {
  name: 'dev'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${adeIdentity.id}': {}
    }
  }
  parent: project
  properties: {
    creatorRoleAssignment: {
      roles: {
        '${contributerRoleDefinition.name}': {}
      }
    }
    userRoleAssignments: reduce(environmentTypeUserRoleAssignments, {}, (cur, next) => union(cur, next))
    #disable-next-line use-resource-id-functions
    deploymentTargetId: subscription().id
    status: 'Enabled'
  }
  dependsOn: [
    environment
  ]
}

module gitHubAppIdentity 'githubIdentity.bicep' = if (gitHubAppRepository != '') {
  name: '${basePrefix}-github-identity'
  params: {
    basePrefix: basePrefix
    location: location
    gitHubAppRepository: gitHubAppRepository
    gitHubAppBranch: gitHubAppBranch
    gitHubAppOwner: gitHubAppOwner
  }
}

// Role Assignments for Deployment Environment
resource deploymentEnvironmentUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '18e40d4e-8d2e-438d-97e1-9528336e149c'
}

resource adeUsersAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for userId in projectAdeUserIds: {
  scope: project
  name: guid(project.name, userId, deploymentEnvironmentUserRole.id)
  properties: {
    roleDefinitionId: deploymentEnvironmentUserRole.id
    principalId: userId
    principalType: 'User'
  }
}]

resource adeGitHubIdentityAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (gitHubAppRepository != '') {
  scope: project
  name: guid(project.name, gitHubAppRepository, deploymentEnvironmentUserRole.id)
  properties: {
    roleDefinitionId: deploymentEnvironmentUserRole.id
    principalId: gitHubAppIdentity.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource devcenterProjectAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '331c37c6-af14-46d9-b9f4-e1909e1b95a0'
}

resource projectAdminAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for userId in projectAdminIds: {
  scope: project
  name: guid(project.name, userId, devcenterProjectAdminRole.id)
  properties: {
    roleDefinitionId: devcenterProjectAdminRole.id
    principalId: userId
    principalType: 'User'
  }
}]

output adeIdentityPrincipalId string = adeIdentity.properties.principalId
output projectEnv string = projectEnvironment.properties.status
output gitHubAppIdentityPrincipalId string = gitHubAppRepository != '' ? gitHubAppIdentity.outputs.identityPrincipalId : ''
output gitHubAppIdentityClientId string = gitHubAppRepository != '' ? gitHubAppIdentity.outputs.identityClientId : ''
