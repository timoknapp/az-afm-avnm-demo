param location_hub string = 'westus'
param location_spoke string = 'eastus'

param networkManagers_avnm_demo_westus_name string = 'avnm-demo-${location_hub}'
param virtualNetworks_vnet_demo_eastus_001_name string = 'vnet-demo-${location_spoke}-001'
param virtualNetworks_vnet_demo_eastus_002_name string = 'vnet-demo-${location_spoke}-002'
param virtualNetworks_vnet_demo_westus_001_name string = 'vnet-demo-${location_hub}-001'
param virtualNetworkGateways_vgw_demo_westus_001_name string = 'vgw-demo-${location_hub}-001'
param publicIPAddresses_pip_vgwdemowestus001_demo_westus_001_name string = 'pip-vgwdemo-${location_hub}-001'

param subscriptionId string = subscription().id

resource networkManagers_avnm_demo_westus_name_resource 'Microsoft.Network/networkManagers@2022-05-01' = {
  name: networkManagers_avnm_demo_westus_name
  location: location_hub
  properties: {
    networkManagerScopes: {
      managementGroups: []
      subscriptions: [
        subscriptionId
      ]
    }
    networkManagerScopeAccesses: [
      'Connectivity'
      'SecurityAdmin'
    ]
  }
}

resource publicIPAddresses_pip_vgwdemowestus001_demo_westus_001_name_resource 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIPAddresses_pip_vgwdemowestus001_demo_westus_001_name
  location: location_hub
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource networkManagers_avnm_demo_westus_name_ng_eastus_001 'Microsoft.Network/networkManagers/networkGroups@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_resource
  name: 'ng-eastus-001'
  properties: {
    description: 'This network group contains virtual networks in the East US Azure region'
  }
}

resource networkManagers_avnm_demo_westus_name_secconf_demo 'Microsoft.Network/networkManagers/securityAdminConfigurations@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_resource
  name: 'secconf-demo'
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [
      'None'
    ]
  }
}

resource virtualNetworkGateways_vgw_demo_westus_001_name_resource 'Microsoft.Network/virtualNetworkGateways@2022-05-01' = {
  name: virtualNetworkGateways_vgw_demo_westus_001_name
  location: location_hub
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_pip_vgwdemowestus001_demo_westus_001_name_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworks_vnet_demo_westus_001_name, 'GatewaySubnet')
          }
        }
      }
    ]
    natRules: []
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: false
    disableIPSecReplayProtection: false
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    bgpSettings: {
      asn: 65515
      // bgpPeeringAddress: '10.3.1.254'
      peerWeight: 0
      bgpPeeringAddresses: [
        {
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', virtualNetworkGateways_vgw_demo_westus_001_name, 'default')
          customBgpIpAddresses: []
        }
      ]
    }
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

resource networkManagers_avnm_demo_westus_name_con_hub_spoke_demo 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_resource
  name: 'con-hub-spoke-demo'
  properties: {
    description: 'This configuration contains a hub virtual network in the West US region.'
    connectivityTopology: 'HubAndSpoke'
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: resourceId('Microsoft.Network/virtualNetworks', virtualNetworks_vnet_demo_westus_001_name)
      }
    ]
    appliesToGroups: [
      {
        networkGroupId: networkManagers_avnm_demo_westus_name_ng_eastus_001.id
        groupConnectivity: 'DirectlyConnected'
        useHubGateway: 'True'
        isGlobal: 'False'
      }
    ]
    deleteExistingPeering: 'False'
    isGlobal: 'False'
  }
}

resource networkManagers_avnm_demo_westus_name_ng_eastus_001_ANM_t2jvmu0x3y 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_ng_eastus_001
  name: 'ANM_t2jvmu0x3y'
  properties: {
    resourceId: virtualNetworks_vnet_demo_eastus_002_name_resource.id
  }
}

resource networkManagers_avnm_demo_westus_name_ng_eastus_001_ANM_t2xwqquz7n 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_ng_eastus_001
  name: 'ANM_t2xwqquz7n'
  properties: {
    resourceId: virtualNetworks_vnet_demo_eastus_001_name_resource.id
  }
}

resource networkManagers_avnm_demo_westus_name_secconf_demo_rc_ngeastus001_demo 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_secconf_demo
  name: 'rc-ngeastus001-demo'
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkManagers_avnm_demo_westus_name_ng_eastus_001.id
      }
    ]
  }
}

resource networkManagers_avnm_demo_westus_name_secconf_demo_rc_ngeastus001_demo_DENY_INTERNET 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
  parent: networkManagers_avnm_demo_westus_name_secconf_demo_rc_ngeastus001_demo
  name: 'DENY_INTERNET'
  kind: 'Custom'
  properties: {
    description: 'This rule blocks traffic to the internet on HTTP and HTTPS'
    priority: 1
    protocol: 'Tcp'
    direction: 'Outbound'
    access: 'Deny'
    sources: []
    destinations: []
    sourcePortRanges: []
    destinationPortRanges: [
      '80'
      '443'
    ]
  }
}

resource virtualNetworks_vnet_demo_eastus_001_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_demo_eastus_001_name
  location: location_spoke
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
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    enableDdosProtection: false
  }
}

resource virtualNetworks_vnet_demo_eastus_002_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_demo_eastus_002_name
  location: location_spoke
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
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    enableDdosProtection: false
  }
}

resource virtualNetworks_vnet_demo_westus_001_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_demo_westus_001_name
  location: location_hub
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
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.3.1.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    enableDdosProtection: false
  }
}
