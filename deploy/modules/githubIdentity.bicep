@description('Prefix for the resources')
param basePrefix string = 'dev0'

@description('Location of the resources')
param location string = resourceGroup().location

@description('GitHub Repository')
param gitHubAppRepository string

@description('GitHub Branch')
param gitHubAppBranch string

@description('GitHub Owner')
param gitHubAppOwner string

// Subject
var subjectPullRequest = 'repo:${gitHubAppOwner}/${gitHubAppRepository}:pull_request'
var subjectRef = 'repo:${gitHubAppOwner}/${gitHubAppRepository}:ref:refs/heads/${gitHubAppBranch}'

// Create managed identity
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${basePrefix}-gh-id'
  location: location
}

// Create fedarated credentials for identity
resource federatedCredentialsPullRequest 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: '${basePrefix}-gh-id-pull'
  parent: identity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: 'https://token.actions.githubusercontent.com'
    subject: subjectPullRequest
  }
}

resource federatedCredentialsBranch 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: '${basePrefix}-gh-id-branch'
  parent: identity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: 'https://token.actions.githubusercontent.com'
    subject: subjectRef
  }

  dependsOn: [
    federatedCredentialsPullRequest
  ] 
}

output identityPrincipalId string = identity.properties.principalId
output identityClientId string = identity.properties.clientId

