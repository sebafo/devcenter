@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Identity of the DevCenter')
param devcenterManagedIdentityId string = '${basePrefix}-dc-id'

@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

var projectName = 'Podcast-App'
var secondProjectName = 'Media-Broker'

// Add an Azure Compute Gallery to the DevCenter
module computeGallery './gallery.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-compute-gallery'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    devcenterManagedIdentityId: devcenterManagedIdentityId
  }
}

// Create a project with the name 'Podcast-App'
module project './project.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: projectName
  params: {
    basePrefix: basePrefix
    location: location
    projectName: projectName
    devcenterName: devcenterName
    projectAdminIds: projectAdminIds
    projectDevBoxUserIds: projectDevBoxUserIds
  }
}

// Create a second project, just to enable the dropdown
module project2 './project.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: secondProjectName
  params: {
    basePrefix: basePrefix
    location: location
    projectName: secondProjectName
    devcenterName: devcenterName
    projectAdminIds: projectAdminIds
    projectDevBoxUserIds: projectDevBoxUserIds
  }
}

// Create a network for the project in europe
module networkeu './network.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-network'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    networkName: '${basePrefix}-eu-vnet'
    networkConnectionName: '${basePrefix}-eu-ncon'
  }
}

// Create a network for the project in us
module networkus './network.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-network-us'
  params: {
    basePrefix: basePrefix
    #disable-next-line no-hardcoded-location
    location: 'eastus'
    devcenterName: devcenterName
    networkConnectionName: '${basePrefix}-ncon-us'
    networkName: '${basePrefix}-vnet-us'
  }
}

// Creat a WebUI devbox definition in the DevCenter
module devBoxDefinitionWebUi './devboxDefinition.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-devbox-webui'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    devBoxDefinitionName: '${basePrefix}-devbox-webui'
    enableHibernateSupport: true
  }
}

// Creat a Backend devbox definition in the DevCenter
module devBoxDefinitionBackend './devboxDefinition.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-devbox-backend'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    devBoxDefinitionName: '${basePrefix}-devbox-backend'
    enableHibernateSupport: true
    computeSku: '16c-64gb'
  }
}

// Creat a AI devbox definition in the DevCenter
module devBoxDefinitionAI './devboxDefinition.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-devbox-ai'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    devBoxDefinitionName: '${basePrefix}-devbox-ai'
    computeSku: '32c-128gb'
  }
}

// Create a WebUi devbox pool EU for the project
module devBoxWebUi './devboxPool.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-pool-webui'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: projectName
    devcenterNetworkConnectionName: networkeu.outputs.networkConnectionName
    devBoxDefinitionName: devBoxDefinitionWebUi.outputs.devBoxDefinitionName
    projectPoolName: '${projectName}-EU-WebUI'
  }
}

// Create a WebUi devbox pool US for the project
module devBoxWebUiUS './devboxPool.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-pool-webui-us'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: projectName
    devcenterNetworkConnectionName: networkus.outputs.networkConnectionName
    devBoxDefinitionName: devBoxDefinitionWebUi.outputs.devBoxDefinitionName
    projectPoolName: '${projectName}-US-WebUI'
  }
}

// Create a Backend devbox pool EU for the project
module devBoxBackend './devboxPool.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-pool-backend'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: projectName
    devcenterNetworkConnectionName: networkeu.outputs.networkConnectionName
    devBoxDefinitionName: devBoxDefinitionBackend.outputs.devBoxDefinitionName
    projectPoolName: '${projectName}-EU-Backend'
  }
}

// Create a AI devbox pool EU for the project
module devBoxAI './devboxPool.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-pool-ai'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: projectName
    devcenterNetworkConnectionName: networkeu.outputs.networkConnectionName
    devBoxDefinitionName: devBoxDefinitionAI.outputs.devBoxDefinitionName
    projectPoolName: '${projectName}-EU-AI'
  }
}

// Create a WebUi devbox pool EU for the second project
module devBoxWebUi2 './devboxPool.bicep' = {
  scope: resourceGroup(resourceGroup().name)
  name: '${basePrefix}-pool-m-webui'
  params: {
    basePrefix: basePrefix
    location: location
    projectName: secondProjectName
    devcenterNetworkConnectionName: networkeu.outputs.networkConnectionName
    devBoxDefinitionName: devBoxDefinitionWebUi.outputs.devBoxDefinitionName
    projectPoolName: '${basePrefix}-pool-m-webui'
  }
}

output projectName string = projectName
