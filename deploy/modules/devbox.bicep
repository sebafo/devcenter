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

@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

@description('Name of the DevBox Definition in the DevCenter')
param devBoxDefinitionName string = '${basePrefix}-devbox1'

@description('Name of the DevBox Pool in the project')
param projectPoolName string = '${basePrefix}-pool1'

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}
resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource devboxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01' = {
  parent: devcenter
  name: devBoxDefinitionName
  location: location
  properties: {
    imageReference: {
      id: '${resourceId('Microsoft.DevCenter/devcenters/galleries', devcenterName, 'Default')}/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
    }
    sku: {
      name: 'general_a_8c32gb_v1'
    }
    osStorageType: 'ssd_512gb'
  }
}

resource projectPool 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
  parent: project
  name: projectPoolName
  location: location
  properties: {
    devBoxDefinitionName: devboxDefinition.name
    networkConnectionName: devcenterNetworkConnectionName
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
  }
}

resource projectPoolSettings 'Microsoft.DevCenter/projects/pools/schedules@2023-04-01' = {
  parent: projectPool
  name: 'default'
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: '19:00'
    timeZone: 'Europe/Berlin'
    state: 'Enabled'
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

resource devcenterDevBoxUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '45d50f46-0b78-4001-a660-4198cbe8cd05'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for userId in projectDevBoxUserIds: {
  scope: project
  name: guid(project.name, userId, devcenterDevBoxUserRole.id)
  properties: {
    roleDefinitionId: devcenterDevBoxUserRole.id
    principalId: userId
    principalType: 'User'
  }
}]
