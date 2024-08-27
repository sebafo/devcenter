@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Project')
param projectName string = '${basePrefix}-project'

@description('List of User ids to assign to the project admin role')
param projectAdminIds array = []

@description('List of User ids to assign to the project DevBox user role')
param projectDevBoxUserIds array = []

// Variables
// DevCenter Dev Box User role 
var DEVCENTER_DEVBOX_USER_ROLE = '45d50f46-0b78-4001-a660-4198cbe8cd05'
var DEVCENTER_PROJECT_ADMIN_ROLE = '331c37c6-af14-46d9-b9f4-e1909e1b95a0'

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2023-04-01' = {
  name: projectName
  location: location
  properties: {
    devCenterId: devcenter.id
  }
}

resource devcenterProjectAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: DEVCENTER_PROJECT_ADMIN_ROLE
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

output projectName string = project.name
