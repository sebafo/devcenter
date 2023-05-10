@description('Basename / Prefix of all resources')
param baseName string = ''

@description('Azure Location/Region')
param location string = 'northeurope'

// Define names
var environmentName = '${baseName}-aca'

// Container Apps Environment
resource environment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: environmentName
  location: location
  properties: {}
}
