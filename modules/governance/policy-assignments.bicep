targetScope = 'subscription'

@description('Location where the policy assignment resource is stored (metadata). Use the same region as the deployment.')
param assignmentLocation string

@description('Name prefix for the policy assignment (e.g., alz-olson-prod-eus)')
param namePrefix string

@description('Built-in policy definition ID for Allowed locations')
param policyDefinitionId string

@description('Allowed Azure locations/regions (e.g., ["eastus","eastus2"])')
param allowedLocations array

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: '${namePrefix}-allowed-locations'
  location: assignmentLocation
  properties: {
    displayName: '${namePrefix} - Allowed Locations'
    policyDefinitionId: policyDefinitionId
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

output assignmentId string = allowedLocationsAssignment.id
output assignmentName string = allowedLocationsAssignment.name

