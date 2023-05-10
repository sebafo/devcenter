@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${basePrefix}-dc-id'
  location: location
}

resource devcenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' = {
  name: devcenterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
}

output devcenterId string = devcenter.id
output devcenterName string = devcenter.name
output devcenterIdentityPricipalId string = devcenter.identity.userAssignedIdentities[identity.id].principalId
