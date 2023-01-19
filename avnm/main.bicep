param location_hub string = 'westeurope'
param location_spoke string = 'northeurope'

param networkManagers_avnm_demo_name string = 'avnm-demo-westeurope'
param virtualNetworks_vnet_demo_001_name string = 'vnet-hub-demo-westeurope-001'
param virtualNetworkGateways_vgw_demo_001_name string = 'vgw-demo-westeurope-001'
param publicIPAddresses_pip_vgw_demo_001_name string = 'pip-vgwdemo-westeurope-001'
param virtualNetworks_vnet_spoke_demo_001_name string = 'vnet-spoke-demo-northeurope-001'
param virtualNetworks_vnet_spoke_demo_002_name string = 'vnet-spoke-demo-northeurope-002'

param subscriptionId string = subscription().id

resource networkManagers_avnm_demo_name_resource 'Microsoft.Network/networkManagers@2022-05-01' = {
  name: networkManagers_avnm_demo_name
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

resource publicIPAddresses_pip_vgw_demo_001_name_resource 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIPAddresses_pip_vgw_demo_001_name
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

resource networkManagers_avnm_demo_name_ng_001_resource 'Microsoft.Network/networkManagers/networkGroups@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_resource
  name: 'ng-${location_spoke}-001'
  properties: {
    description: 'This network group contains virtual networks in the ${location_spoke} Azure region'
  }
}

resource networkManagers_avnm_demo_name_secconf_demo 'Microsoft.Network/networkManagers/securityAdminConfigurations@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_resource
  name: 'secconf-demo'
  properties: {
    applyOnNetworkIntentPolicyBasedServices: [
      'None'
    ]
  }
}

resource virtualNetworkGateways_vgw_demo_001_name_resource 'Microsoft.Network/virtualNetworkGateways@2022-05-01' = {
  name: virtualNetworkGateways_vgw_demo_001_name
  location: location_hub
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddresses_pip_vgw_demo_001_name_resource.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworks_vnet_demo_001_name, 'GatewaySubnet')
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
      peerWeight: 0
      bgpPeeringAddresses: [
        {
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', virtualNetworkGateways_vgw_demo_001_name, 'default')
          customBgpIpAddresses: []
        }
      ]
    }
    vpnGatewayGeneration: 'Generation1'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

resource networkManagers_avnm_demo_name_con_hub_spoke_demo 'Microsoft.Network/networkManagers/connectivityConfigurations@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_resource
  name: 'con-hub-spoke-demo'
  properties: {
    description: 'This configuration contains a hub virtual network in the ${location_hub} region.'
    connectivityTopology: 'HubAndSpoke'
    hubs: [
      {
        resourceType: 'Microsoft.Network/virtualNetworks'
        resourceId: resourceId('Microsoft.Network/virtualNetworks', virtualNetworks_vnet_demo_001_name)
      }
    ]
    appliesToGroups: [
      {
        networkGroupId: networkManagers_avnm_demo_name_ng_001_resource.id
        groupConnectivity: 'DirectlyConnected'
        useHubGateway: 'True'
        isGlobal: 'False'
      }
    ]
    deleteExistingPeering: 'False'
    isGlobal: 'False'
  }
}

resource networkManagers_avnm_demo_name_ng_001_ANM_t2jvmu0x3y 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_ng_001_resource
  name: 'ANM_t2jvmu0x3y'
  properties: {
    resourceId: virtualNetworks_vnet_spoke_demo_002_name_resource.id
  }
}

resource networkManagers_avnm_demo_name_ng_001_ANM_t2xwqquz7n 'Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_ng_001_resource
  name: 'ANM_t2xwqquz7n'
  properties: {
    resourceId: virtualNetworks_vnet_spoke_demo_001_name_resource.id
  }
}

resource networkManagers_avnm_demo_name_secconf_demo_rc_001_demo 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_secconf_demo
  name: 'rc-ng-${location_spoke}-001'
  properties: {
    appliesToGroups: [
      {
        networkGroupId: networkManagers_avnm_demo_name_ng_001_resource.id
      }
    ]
  }
}

resource networkManagers_avnm_demo_name_secconf_demo_rc_01_demo_DENY_INTERNET 'Microsoft.Network/networkManagers/securityAdminConfigurations/ruleCollections/rules@2022-05-01' = {
  parent: networkManagers_avnm_demo_name_secconf_demo_rc_001_demo
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

resource virtualNetworks_vnet_spoke_demo_001_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_spoke_demo_001_name
  location: location_spoke
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.4.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-spoke-001'
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

resource virtualNetworks_vnet_spoke_demo_002_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_spoke_demo_002_name
  location: location_spoke
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.5.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-spoke-002'
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

resource virtualNetworks_vnet_demo_001_name_resource 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworks_vnet_demo_001_name
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

resource publicIP_spoke_VM_001 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'pip-vm-spoke-001'
  location: location_spoke
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource publicIP_spoke_VM_002 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'pip-vm-spoke-002'
  location: location_spoke
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}


resource netInterface_vm_spoke_001 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'nic-01-vm-spoke-${location_spoke}-001'
  location: location_spoke
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworks_vnet_spoke_demo_001_name_resource.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg_spoke_001.id
    }
  }
}



resource netInterface_vm_spoke_002 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'nic-01-vm-spoke-${location_spoke}-002'
  location: location_spoke
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworks_vnet_spoke_demo_002_name_resource.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg_spoke_002.id
    }
  }
}

resource nsg_spoke_001 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: 'nsg-spoke-001'
  location: location_spoke
  properties: {}
}

resource nsg_spoke_002 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: 'nsg-workload-srv'
  location: location_spoke
  properties: {}
}

@description('Admin username for the servers')
param adminUsername string = 'adminuser'

@description('Password for the admin account on the servers')
@secure()
param adminPassword string

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2_v3'

resource VM_Spoke_001 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'vm-spoke-${location_spoke}-001'
  location: location_spoke
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: 'vmworkload'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: netInterface_vm_spoke_001.id
        }
      ]
    }
  }
}

resource VM_Spoke_002 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'vm-spoke-${location_spoke}-002'
  location: location_spoke
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: 'vmworkload'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: netInterface_vm_spoke_002.id
        }
      ]
    }
  }
}

