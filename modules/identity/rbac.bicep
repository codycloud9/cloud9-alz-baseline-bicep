targetScope = 'subscription'

@description('Object ID (principalId) of Entra user/group/service principal to grant access to.')
param principalId string

@allowed([
  'Reader'
  'Contributor'
])
@description('Built-in role to assign.')
param roleName string = 'Reader'

// Built-in role definition GUIDs (these are Microsoft global constants)
var readerRoleGuid = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleGuid = 'b24988ac-6180-42f0-ab88-20f7382dd24c'

var roleGuid = roleName == 'Contributor' ? contributorRoleGuid : readerRoleGuid
var roleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleGuid)

// Deterministic name so redeployments don’t create duplicates
var assignmentName = guid(subscription().id, principalId, roleDefinitionId)

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: assignmentName
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    principalType: 'Group' // if you use a group. If you use a user/SP, change this or remove it.
  }
}

output roleAssigned string = roleName
output principalAssigned string = principalId
