@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the DevBox Definition in the DevCenter')
param devBoxDefinitionName string = '${basePrefix}-devbox1'

@description('Compute SKU for the DevBox')
param computeSku string = '8c-32gb'

@description('Enable Hibernate Support')
param enableHibernateSupport bool = false

// Variables
var hibernateSupportEnabled = enableHibernateSupport ? 'Enabled' : 'Disabled'

// az devcenter admin sku list --query "[].name"
/*
  "general_i_16c64gb1024ssd_v2",
  "general_i_16c64gb2048ssd_v2",
  "general_i_16c64gb256ssd_v2",
  "general_i_16c64gb512ssd_v2",
  "general_i_32c128gb1024ssd_v2",
  "general_i_32c128gb2048ssd_v2",
  "general_i_32c128gb512ssd_v2",
  "general_i_8c32gb1024ssd_v2",
  "general_i_8c32gb2048ssd_v2",
  "general_i_8c32gb256ssd_v2",
  "general_i_8c32gb512ssd_v2"
*/
var compute = {
  '8c-32gb': 'general_i_8c32gb256ssd_v2'
  '16c-64gb': 'general_i_16c64gb256ssd_v2'
  '32c-128gb': 'general_i_32c128gb512ssd_v2'
}

// var storage = {
//   '8c-32gb': 'ssd_256gb'
//   '16c-64gb': 'ssd_512gb'
//   '32c-128gb': 'ssd_1024gb'
// }

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}

resource devboxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2023-04-01' = {
  parent: devcenter
  name: devBoxDefinitionName
  location: location
  properties: {
    imageReference: {
      #disable-next-line use-resource-id-functions
      id: '${resourceId('Microsoft.DevCenter/devcenters/galleries', devcenterName, 'Default')}/images/microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
    }
    hibernateSupport: hibernateSupportEnabled
    sku: {
      name: compute[computeSku]
    }
  }
}

output devBoxDefinitionName string = devboxDefinition.name
