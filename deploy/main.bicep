targetScope = 'subscription'

// Basic Parameters
@description('Prefix for the resources')
param basePrefix string

// Generated Parameters
@description('Name of the resouce group')
param resourceGroupName string = '${basePrefix}-rg'

@description('Location of the resources')
param location string = 'westeurope'

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

// GitHub parameters
@description('Path in the GitHub repository')
param gitHubPath string

@description('URL to the GitHub repository')
param gitHubUrl string

@secure()
@description('PAT for the GitHub repository')
param gitHubPat string = ''

// Conditional Parameters
@description('Deploy DevBox resources')
param deployDevBox bool = false

@description('Deploy ADE resources')
param deployAde bool = false

// Role Assignments
@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project ADE user role')
param projectAdeUserIds array = []

// Deployments
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module devcenter './modules/devcenter.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: devcenterName
  params: {
    location: location
    basePrefix: basePrefix
  }

  dependsOn: [
    rg
  ]
}

module project './modules/project.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: projectName
  params: {
    location: location
    devcenterName: devcenter.outputs.devcenterName
    basePrefix: basePrefix
    projectAdeUserIds: projectAdeUserIds
    projectAdminIds: projectAdminIds
  }

  dependsOn: [
    rg
  ]
}

module network './modules/network.bicep' = if (deployDevBox) {
  scope: resourceGroup(resourceGroupName)
  name: '${basePrefix}-network'
  params: {
    location: location
    devcenterName: devcenter.outputs.devcenterName
    basePrefix: basePrefix
  }

  dependsOn: [
    rg
  ]
}

module keyVault './modules/keyvault.bicep' = if (deployAde) {
  scope: resourceGroup(resourceGroupName)
  name: '${basePrefix}-keyvault'
  params: {
    location: location
    basePrefix: basePrefix
    gitHubPat: gitHubPat
  }

  dependsOn: [
    rg
  ]
}

module ade './modules/ade.bicep' = if (deployAde) {
  scope: resourceGroup(resourceGroupName)
  name: '${basePrefix}-ade'
  params: {
    location: location
    basePrefix: basePrefix
    keyVaultName: keyVault.outputs.keyVaultName
    gitHubPath: gitHubPath
    gitHubUrl: gitHubUrl
    gitHubTokenPath: keyVault.outputs.secretUri
  }

  dependsOn: [
    rg, keyVault
  ]
}

module AdeIdOwnerRoleAssignement './modules/subscriptionOwnerRole.bicep' = if (deployAde) {
  name: '${basePrefix}-owner-identity'
  params: {
    identityPrincipalIds: [ade.outputs.adeIdentityPrincipalId, devcenter.outputs.devcenterIdentityPricipalId]
  }

  dependsOn: [
    ade
  ]
}
