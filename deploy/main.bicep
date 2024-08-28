targetScope = 'subscription'

// Basic Parameters
@description('Prefix for the resources')
param basePrefix string

// Generated Parameters
@description('Name of the resouce group')
param resourceGroupName string = '${basePrefix}-rg'

@description('Location of the resources')
param location string = 'northeurope'

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

// Conditional Parameters
@description('Deploy DevBox resources')
param deployDevBox bool = false

@description('Deploy ADE resources')
param deployAde bool = false

@description('Deploy Podcast Example')
param deployPodcastExample bool = false

// ADE GitHub parameters
@description('Path in the GitHub repository')
param gitHubPath string = ''

@description('URL to the GitHub repository')
param gitHubUrl string = ''

@secure()
@description('PAT for the GitHub repository')
param gitHubPat string = ''

// Role Assignments
@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

@description('List of User ids to assign to the project ADE user role')
param projectAdeUserIds array = []

// Integrate with GitHub Actions in a GitHub repository
@description('GitHub Repository')
param gitHubAppRepository string = ''

@description('GitHub Branch')
param gitHubAppBranch string = ''

@description('GitHub Owner')
param gitHubAppOwner string = ''

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
    enableCustomizations: true
  }
}

module devBox './modules/simpleExample.bicep' = if (deployDevBox || deployAde) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-devbox'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenter.outputs.devcenterName
    projectName: projectName
    projectDevBoxUserIds: projectDevBoxUserIds
    projectAdminIds: projectAdminIds
  }

  dependsOn: [
    devcenter
  ]
}

module podcastApp './modules/podcastExample.bicep' = if (deployPodcastExample) {
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-podcast'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenter.outputs.devcenterName
    devcenterManagedIdentityId: devcenter.outputs.devcenterIdentityPricipalId
    projectAdminIds: projectAdminIds
    projectDevBoxUserIds: projectDevBoxUserIds
  }

  dependsOn: [
    devcenter
  ]
}

module ade './modules/ade.bicep' = if (deployAde || deployPodcastExample) {  
  scope: resourceGroup(rg.name)
  name: '${basePrefix}-podcast-ade'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: (deployPodcastExample) ? podcastApp.outputs.projectName : projectName
    gitHubPath: gitHubPath
    gitHubUrl: gitHubUrl
    gitHubPat: gitHubPat
    projectAdeUserIds: projectAdeUserIds
    projectAdminIds: projectAdminIds
    gitHubAppBranch: gitHubAppBranch
    gitHubAppOwner: gitHubAppOwner
    gitHubAppRepository: gitHubAppRepository
  }

  dependsOn: [
    podcastApp, devBox
  ]
}

module AdeIdOwnerRoleAssignement './modules/subscriptionOwnerRole.bicep' = if (deployAde || deployPodcastExample) {
  name: '${basePrefix}-owner-identity'
  params: {
    identityPrincipalIds: [ade.outputs.adeIdentityPrincipalId, devcenter.outputs.devcenterIdentityPricipalId, ade.outputs.gitHubAppIdentityPrincipalId]
  }
}

