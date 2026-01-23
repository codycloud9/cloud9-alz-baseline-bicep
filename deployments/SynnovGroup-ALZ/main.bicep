targetScope = 'subscription'

@description('Customer name used for naming/tagging')
param customerName string

@description('Environment tag value (Prod/Dev/Test)')
param environment string

@description('Azure region')
param location string

@description('Cost center tag')
param costCenter string

@description('Owner tag')
param owner string

@description('Networking RG name')
param netRgName string

@description('Hub VNet name')
param hubVnetName string

@description('Hub CIDR(s)')
param hubAddressPrefixes array

@description('Spoke VNet name')
param spokeVnetName string

@description('Spoke CIDR(s)')
param spokeAddressPrefixes array

@description('Hub subnet prefix for AzureFirewallSubnet')
param firewallSubnetPrefix string

@description('Hub subnet prefix for GatewaySubnet')
param gatewaySubnetPrefix string

@description('Hub subnet prefix for shared services subnet')
param hubSharedSubnetPrefix string

@description('Spoke subnet prefix for workload subnet')
param workloadSubnetPrefix string

@description('Entra Object ID (principalId) of the group to grant landing zone access to')
param rbacPrincipalId string

@allowed([
  'Reader'
  'Contributor'
])
@description('RBAC role to assign')
param rbacRoleName string = 'Reader'

/*** GOVERNANCE (Allowed Locations + Delete Lock) ***/
@description('Name prefix for governance artifacts (policy assignment/lock names). Example: alz-synnov-prod-wus2')
param govNamePrefix string

@description('Allowed Azure locations for this subscription. Example: ["westus2"]')
param allowedLocations array

@description('Built-in policy definition id for Allowed locations')
param allowedLocationsPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

@description('Enable delete lock (CanNotDelete) on the landing zone networking RG')
param enableDeleteLock bool = true

var tags = {
  Customer: customerName
  Environment: environment
  Owner: owner
  CostCenter: costCenter
  DeploymentMethod: 'IaC'
  BaselineVersion: 'v1.0'
}

resource netRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: netRgName
  location: location
  tags: tags
}

module net '../../modules/networking/networking.bicep' = {
  name: 'networking-${customerName}-${environment}'
  scope: netRg
  params: {
    location: location
    tags: tags
    hubVnetName: hubVnetName
    hubAddressPrefixes: hubAddressPrefixes
    spokeVnetName: spokeVnetName
    spokeAddressPrefixes: spokeAddressPrefixes

    firewallSubnetPrefix: firewallSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    hubSharedSubnetPrefix: hubSharedSubnetPrefix
    workloadSubnetPrefix: workloadSubnetPrefix
  }
}

module rbac '../../modules/identity/rbac.bicep' = {
  name: 'rbac-${customerName}-${environment}'
  params: {
    principalId: rbacPrincipalId
    roleName: rbacRoleName
  }
}

/*** Governance: Allowed Locations Policy Assignment ***/
module governance '../../modules/governance/policy-assignments.bicep' = {
  name: 'governance-${customerName}-${environment}'
  params: {
    assignmentLocation: location
    namePrefix: govNamePrefix

    enableAllowedLocations: true
    allowedLocations: allowedLocations

    // keep off for baseline to avoid breaking workloads
    enableAllowedVmSkus: false
    allowedVmSkus: []

    enableAllowedResourceTypes: false
    allowedResourceTypes: []

    allowedLocationsPolicyDefinitionId: allowedLocationsPolicyDefinitionId

    // If your policy-assignments module requires these, leave placeholders.
    // If you made them optional in the module, DELETE these two lines.
    allowedVmSkusPolicyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000'
    allowedResourceTypesPolicyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/00000000-0000-0000-0000-000000000000'
  }
}

/*** Governance: Delete Lock (NOT a policy) ***/
module deleteLock '../../modules/governance/delete-lock.bicep' = if (enableDeleteLock) {
  name: 'deleteLock-${customerName}-${environment}'
  params: {
    rgName: netRgName
    lockName: '${govNamePrefix}-cannotdelete'
  }
}

output hubVnetId string = net.outputs.hubVnetId
output spokeVnetId string = net.outputs.spokeVnetId
output netRgId string = netRg.id
output rbacRoleAssigned string = rbac.outputs.roleAssigned
output rbacPrincipalAssigned string = rbac.outputs.principalAssigned
output allowedLocationsPolicyAssignmentName string = governance.outputs.allowedLocationsAssignmentName
output deleteLockId string = enableDeleteLock ? deleteLock.outputs.lockId : ''
