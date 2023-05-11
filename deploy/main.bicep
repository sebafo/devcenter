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

// ADE GitHub parameters
@description('Path in the GitHub repository')
param gitHubPath string = ''

@description('URL to the GitHub repository')
param gitHubUrl string = ''

@secure()
@description('PAT for the GitHub repository')
param gitHubPat string = ''

// Conditional Parameters
@description('Deploy DevBox resources')
param deployDevBox bool = false

@description('Deploy ADE resources')
param deployAde bool = false

// DevBox parmeters - currently only one project, one DevBox definition and one pool is supported in this repo. TODO: make this more flexible
@description('Name of the DevBox Definition in the DevCenter')
param devBoxDefinitionName string = '${basePrefix}-devbox1'

@description('Name of the DevBox Pool in the project')
param projectDevBoxPoolName string = '${basePrefix}-pool1'

// Role Assignments
@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

@description('List of User ids to assign to the project ADE user role')
param projectAdeUserIds array = []

// Deployments
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module devcenter './modules/devcenter.bicep' = {
  scope: resourceGroup(rg.name)
  name: devcenterName
  params: {
    basePrefix: basePrefix
    location: location
  }
}

module project './modules/project.bicep' = {
  scope: resourceGroup(rg.name)
  name: projectName
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenter.outputs.devcenterName
  }
}

module network './modules/network.bicep' = if (deployDevBox) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-network'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenter.outputs.devcenterName
  }

  dependsOn: [
    devcenter
  ]
}

module devBox './modules/devbox.bicep' = if (deployDevBox) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-devbox'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenter.outputs.devcenterName
    projectName: project.outputs.projectName
    devcenterNetworkConnectionName: deployDevBox ? network.outputs.networkConnectionName : ''
    devBoxDefinitionName: devBoxDefinitionName
    projectPoolName: projectDevBoxPoolName
    projectAdminIds: projectAdminIds
    projectDevBoxUserIds: projectDevBoxUserIds
  }

  dependsOn: [
    devcenter, network
  ]
}

module keyVault './modules/keyvault.bicep' = if (deployAde) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-keyvault'
  params: {
    basePrefix: basePrefix
    location: location
    gitHubPat: gitHubPat
  }
}

module ade './modules/ade.bicep' = if (deployAde) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-ade'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: project.outputs.projectName
    keyVaultName: deployAde ? keyVault.outputs.keyVaultName : ''
    gitHubPath: gitHubPath
    gitHubUrl: gitHubUrl
    gitHubTokenPath: deployAde ? keyVault.outputs.secretUri : ''
    projectAdeUserIds: projectAdeUserIds
    projectAdminIds: projectAdminIds
  }

  dependsOn: [
    keyVault
  ]
}

module AdeIdOwnerRoleAssignement './modules/subscriptionOwnerRole.bicep' = if (deployAde) {
  name: '${basePrefix}-owner-identity'
  params: {
    identityPrincipalIds: deployAde ? [ade.outputs.adeIdentityPrincipalId, devcenter.outputs.devcenterIdentityPricipalId] : []
  }

  dependsOn: [
    ade
  ]
}
