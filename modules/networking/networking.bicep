targetScope = 'resourceGroup'

@description('Azure region for all networking resources')
param location string

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

@description('Hub subnet prefix for AzureFirewallSubnet')
param firewallSubnetPrefix string

@description('Hub subnet prefix for GatewaySubnet')
param gatewaySubnetPrefix string

@description('Hub subnet prefix for shared services subnet')
param hubSharedSubnetPrefix string

@description('Spoke subnet prefix for workload subnet')
param workloadSubnetPrefix string

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
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: 'Hub-Shared'
        properties: {
          addressPrefix: hubSharedSubnetPrefix
        }
      }
    ]
  }
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
        properties: {
          addressPrefix: workloadSubnetPrefix
        }
      }
    ]
  }
}

resource peerHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: 'to-${spokeVnetName}'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

resource peerSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  name: 'to-${hubVnetName}'
  parent: spokeVnet
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}

output hubVnetId string = hubVnet.id
output spokeVnetId string = spokeVnet.id
