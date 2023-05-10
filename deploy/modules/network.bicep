@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

resource devcenter 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource devcenterVnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: '${basePrefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource devcenterNetworkConnection 'Microsoft.DevCenter/networkconnections@2022-11-11-preview' = {
  name: '${basePrefix}-ncon'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: devcenterVnet.properties.subnets[0].id
  }
}

resource devcenterNetworkConnectionAttach 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  parent: devcenter
  name: '${basePrefix}-ncon'
  properties: {
    networkConnectionId: devcenterNetworkConnection.id
  }
}
