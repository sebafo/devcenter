@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Enable Dev Box customizations')
param enableCustomizations bool = false

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${basePrefix}-dc-id'
  location: location
}

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: devcenterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
}

// Enable customizations by adding the microsoft catalog
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-04-01' = if (enableCustomizations){
  name: 'MSFT-Example-Tasks'
  parent: devcenter
  properties: {
    gitHub: {
      uri: 'https://github.com/microsoft/devcenter-catalog.git'
      branch: 'main'
      path: 'Tasks'
    }
  }
}

output devcenterId string = devcenter.id
output devcenterName string = devcenter.name
output devcenterIdentityPricipalId string = devcenter.identity.principalId
