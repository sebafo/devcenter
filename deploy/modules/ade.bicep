// Azure Deployment Environment
@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('KeyVault with GitHub PAT')
param keyVaultName string

@description('DevCenter name')
param devcenterName string = '${basePrefix}-devcenter'

@description('Project name')
param projectName string = '${basePrefix}-project'

param identityName string = '${basePrefix}-dc-id'

param catalogName string = '${basePrefix}-catalog'
param gitHubUrl string
param gitHubBranch string = 'main'
param gitHubPath string
param gitHubTokenPath string

// Read existing resources
resource devcenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: projectName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Role assignment for the identity to access Key Vault
@description('This is the built-in Azure KeyVault Secrets User role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user')
resource secretsUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6'
}

resource roleAssignement 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(resourceGroup().id, identity.id, secretsUserRoleDefinition.id)
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: secretsUserRoleDefinition.id
  }
}

// DevCenter Resources
// Create the catalog
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = {
  name: catalogName
  parent: devcenter
  properties: {
    gitHub: {
      uri: gitHubUrl
      branch: gitHubBranch
      path: gitHubPath
      secretIdentifier: gitHubTokenPath
    }
  }

  dependsOn: [
    roleAssignement
  ]
}

// Create an environment in DevCenter
resource environment 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = {
  name: 'dev'
  parent: devcenter
}

// Project Resources
resource adeIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${basePrefix}-ade-id'
  location: location
}

@description('This is the built-in Owner role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#owner')
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

resource projectEnvironment 'Microsoft.DevCenter/projects/environmentTypes@2022-09-01-preview' = {
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
        '${ownerRoleDefinition.name}': {}
      }
    }
#disable-next-line use-resource-id-functions
    deploymentTargetId: subscription().id
    status: 'Enabled'
  }
  dependsOn: [
    environment
  ]
}

output adeIdentityPrincipalId string = adeIdentity.properties.principalId
output projectEnv string = projectEnvironment.properties.status
