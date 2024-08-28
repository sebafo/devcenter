@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('Name of the DevCenter')
param devcenterName string = '${basePrefix}-devcenter'

@description('Name of the Azure Compute Gallery')
param computeGalleryName string = replace('${basePrefix}gallery', '-', '')

@description('Identity of the DevCenter')
param devcenterManagedIdentityId string = '${basePrefix}-devcenter-id'

// Variables
var CONTRIBUTOR_ROLE = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var READER_ROLE = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// Used when Dev Center associate with Azure Compute Gallery
//var WINDOWS365_PRINCIPALID = '8eec7c09-06ae-48e9-aafd-9fb31a5d5175' // az ad sp list --display-name 'Windows 365' --query "[].id" -o tsv ----OR----- az ad sp show --id 0af06dc6-e4b5-4f28-818e-e78e62d137a5 --query id -o tsv
var WINDOWS365_PRINCIPALID = '1b315949-7e8c-4204-9ab6-f9b8c3d02f63'

resource devcenter 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devcenterName
}

// Azure Compute Gallery
resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: computeGalleryName
  location: location
}

// Grant the DevCenter identity contributer access to the gallery
// Contributer Role
resource contributerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: CONTRIBUTOR_ROLE
}

resource galleryContributerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(computeGalleryName, devcenterManagedIdentityId, contributerRole.id)
  scope: gallery
  properties: {
    principalId: devcenterManagedIdentityId
    roleDefinitionId: contributerRole.id
    principalType: 'ServicePrincipal'
  }
}

// Grant Reader Role to Windows 365 Service Principal
resource readerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: READER_ROLE
}

resource galleryReaderRoleAssignement 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(computeGalleryName, 'Windows365', readerRole.id)
  properties: {
    principalId: WINDOWS365_PRINCIPALID
    roleDefinitionId: readerRole.id
    principalType: 'ServicePrincipal'
  }
}

// Attach a gallery to a dev center
resource attachGallery 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: computeGalleryName
  parent: devcenter
  properties: {
    galleryResourceId: gallery.id
  }
}

resource galleryImage 'Microsoft.DevCenter/devcenters/galleries/images@2023-04-01' existing = {
  name: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
  parent: attachGallery
}

output galleryImageName string = galleryImage.name
output galleryImageId string = galleryImage.id
