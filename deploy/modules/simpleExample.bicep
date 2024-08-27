@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the DevCenter Network Connection')
param devcenterNetworkConnectionName string = '${basePrefix}-ncon'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

@description('Deploy DevBox resources')
param deployDevBox bool = false

@description('Name of the DevBox Definition in the DevCenter')
param devBoxDefinitionName string = '${basePrefix}-devbox1'

@description('Name of the DevBox Pool in the project')
param projectPoolName string = '${basePrefix}-pool1'

@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

@description('Compute SKU for the DevBox')
param computeSku string = '8c-32gb'

@description('Enable Hibernate Support')
param enableHibernateSupport bool = false

module network './network.bicep' = if (deployDevBox)  {
  name: '${basePrefix}-network'
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
  }
}

// Create DevBox Definition
module devboxDefinition './devboxDefinition.bicep' = if (deployDevBox) {
  name: devBoxDefinitionName
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    computeSku: computeSku
    enableHibernateSupport: enableHibernateSupport
  }
}

module project './project.bicep' = {
  name: projectName
  params: {
    basePrefix: basePrefix
    location: location
    devcenterName: devcenterName
    projectAdminIds: projectAdminIds
  }
}

// Create DevBox Pool
module devboxPool './devboxPool.bicep' = if (deployDevBox) {
  name: projectPoolName
  params: {
    basePrefix: basePrefix
    location: location
    devcenterNetworkConnectionName: devcenterNetworkConnectionName
    projectName: projectName
    devBoxDefinitionName: devBoxDefinitionName
    projectPoolName: projectPoolName
    projectDevBoxUserIds: projectDevBoxUserIds
  }
}

output projectName string = projectName
