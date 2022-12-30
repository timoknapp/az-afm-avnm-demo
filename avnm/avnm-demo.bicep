@description('Location for the first vnet.')
param firstLocation string = 'West US'

resource virtualNetwork1 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'VNet-A-WestUS'
  location: firstLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.3.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.3.0.0/24'
        }
      }
      {
         name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.3.1.0/24'
        }
      }
    ]
  }
}

@description('Location for the second and third vnet.')
param secondLocation string = 'East US'

resource virtualNetwork2 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'VNet-A-EastUS'
  location: secondLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.4.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.4.0.0/24'
        }
      }
    ]
  }
}

resource virtualNetwork3 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'VNet-B-EastUS'
  location: secondLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.5.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.5.0.0/24'
        }
      }
    ]
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'VNet-A-WestUS-GW-IP'
  location: firstLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'VNet-A-WestUS-GW'
  location: firstLocation
  properties: {
    ipConfigurations: [
      {
        name: 'VNet-A-WestUS-GW-IP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork1.properties.subnets[1].id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGW1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    enableBgp: false
  }
}

resource virtualNetworkManager 'Microsoft.Network/networkManagers@2022-05-01' = {
  name: 'myAVNM'
  location: firstLocation
  properties: {
    description: 'string'
    networkManagerScopeAccesses: [
      'Connectivity','SecurityAdmin'
    ]
    networkManagerScopes: {
      subscriptions: [
        subscription().subscriptionId
      ]
    }
  }
}

resource networkGroup 'Microsoft.Network/networkManagers/networkGroups@2022-05-01' = {
  name: 'myNetworkGroupB'
  parent: virtualNetworkManager
  properties: {
    description: 'This network group contains virtual networks in the East US Azure region.'
  }
}

resource staticNetworkGroupMemberVNet2 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  name: 'VNetAZStaticMember1'
  parent: networkGroup
  properties: {
    resourceId: virtualNetwork2.id
  }
}

resource staticNetworkGroupMemberVNet3 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  name: 'VNetAZStaticMember2'
  parent: networkGroup
  properties: {
    resourceId: virtualNetwork3.id
  }
}

resource hubA 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = {
  name: 'HubA'
  parent: virtualNetworkManager
  properties: {
    appliesToGroups: [
      {
        groupConnectivity: 'DirectlyConnected'
        isGlobal: 'False'
        networkGroupId: networkGroup.id
        useHubGateway: 'True'
      }
    ]
    connectivityTopology: 'HubAndSpoke'
    description: 'This configuration contains a hub virtual network in the West US Azure region.'
    hubs: [
      {
        resourceId: virtualNetwork1.id
        resourceType: virtualNetwork1.type
      }
    ]
    isGlobal: 'False'
  }
}

resource securityAdminConfigurations 'Microsoft.Network/networkManagers/securityAdminConfigurations@2022-05-01' = {
  name: 'mySecurityConfig'
  parent: virtualNetworkManager
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [
      'All'
    ]
    description: ''
  }
}

resource securityAdminRuleCollection 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2022-05-01' = {
  name: 'myRuleCollection'
  parent: securityAdminConfigurations
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkGroup.id
      }
    ]
    description: ''
  }
}

resource rule 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
  name: 'DENY_INTERNET'
  parent: securityAdminRuleCollection
  kind: 'Custom'
  properties: {
    access: 'Deny'
    description: 'This rule blocks traffic to the internet on HTTP and HTTPS.'
    destinationPortRanges: [
      '80','443'
    ]
    destinations: [
      {
        addressPrefix: ''
        addressPrefixType: 'IPPrefix'
      }
    ]
    direction: 'Outbound'
    priority: 1
    protocol: 'Tcp'
    sourcePortRanges: [
    ]
    sources: [
      {
        addressPrefix: ''
        addressPrefixType: 'IPPrefix'
      }
    ]
  }
}
