@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Network')
param networkName string = '${basePrefix}-vnet'

@description('Name of the Network connection')
param networkConnectionName string = '${basePrefix}-ncon'

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}

resource devcenterVnet 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: networkName
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

resource devcenterNetworkConnection 'Microsoft.DevCenter/networkconnections@2023-04-01' = {
  name: networkConnectionName
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: devcenterVnet.properties.subnets[0].id
  }
}

resource devcenterNetworkConnectionAttach 'Microsoft.DevCenter/devcenters/attachednetworks@2023-04-01' = {
  parent: devcenter
  name: networkConnectionName
  properties: {
    networkConnectionId: devcenterNetworkConnection.id
  }
}

output networkConnectionName string = devcenterNetworkConnection.name
