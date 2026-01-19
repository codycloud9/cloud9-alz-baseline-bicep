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

@description('Entra Object ID (principalId) of the group to grant landing zone access to')
param rbacPrincipalId string

@allowed([
  'Reader'
  'Contributor'
])
@description('RBAC role to assign')
param rbacRoleName string = 'Reader'

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
  }
}

module rbac '../../modules/identity/rbac.bicep' = {
  name: 'rbac-${customerName}-${environment}'
  params: {
    principalId: rbacPrincipalId
    roleName: rbacRoleName
  }
}

output hubVnetId string = net.outputs.hubVnetId
output spokeVnetId string = net.outputs.spokeVnetId
output netRgId string = netRg.id
output rbacRoleAssigned string = rbac.outputs.roleAssigned
output rbacPrincipalAssigned string = rbac.outputs.principalAssigned
