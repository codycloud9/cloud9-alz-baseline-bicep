targetScope = 'subscription'

@description('Azure region for all networking resources')
param location string

@description('Resource Group name for networking resources')
param rgName string

@description('Tags applied to all resources created by this module')
param tags object

@description('Hub VNet name')
param hubVnetName string

@description('Hub VNet CIDR(s)')
param hubAddressPrefixes array

@description('Spoke VNet name')
param spokeVnetName string

@description('Spoke VNet CIDR(s)')
param spokeAddressPrefixes array

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: tags
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: hubAddressPrefixes
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: { addressPrefix: '10.0.0.0/26' }
      }
      {
        name: 'GatewaySubnet'
        properties: { addressPrefix: '10.0.0.64/27' }
      }
      {
        name: 'Hub-Shared'
        properties: { addressPrefix: '10.0.1.0/24' }
      }
    ]
  }
  scope: rg
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: spokeVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: spokeAddressPrefixes
    }
    subnets: [
      {
        name: 'Workload'
        properties: { addressPrefix: '10.1.1.0/24' }
      }
    ]
  }
  scope: rg
}

resource peerHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${hubVnet.name}/to-${spokeVnet.name}'
  properties: {
    remoteVirtualNetwork: { id: spokeVnet.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
  }
  scope: rg
}

resource peerSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: '${spokeVnet.name}/to-${hubVnet.name}'
  properties: {
    remoteVirtualNetwork: { id: hubVnet.id }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
  scope: rg
}

output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
output rgId string = rg.id
