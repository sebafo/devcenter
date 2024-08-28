@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter Network Connection')
param devcenterNetworkConnectionName string = '${basePrefix}-ncon'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

@description('Name of the DevBox Definition in the DevCenter')
param devBoxDefinitionName string = '${basePrefix}-devbox1'

@description('Name of the DevBox Pool in the project')
param projectPoolName string = '${basePrefix}-pool1'

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

// Variables
var DEVCENTER_DEVBOX_USER_ROLE = '45d50f46-0b78-4001-a660-4198cbe8cd05'

// var storage = {
//   '8c-32gb': 'ssd_256gb'
//   '16c-64gb': 'ssd_512gb'
//   '32c-128gb': 'ssd_1024gb'
// }

resource project 'Microsoft.DevCenter/projects@2023-04-01' existing = {
  name: projectName
}

resource projectPool 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
  parent: project
  name: projectPoolName
  location: location
  properties: {
    devBoxDefinitionName: devBoxDefinitionName
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

resource devcenterDevBoxUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: DEVCENTER_DEVBOX_USER_ROLE
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
