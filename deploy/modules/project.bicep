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

@description('List of User ids to assign to the project ADE user role')
param projectAdeUserIds array = []

resource devcenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: projectName
  location: location
  properties: {
    devCenterId: devcenter.id
  }
}

#disable-next-line no-unused-existing-resources
resource devcenterDevBoxUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '45d50f46-0b78-4001-a660-4198cbe8cd05'
}

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
