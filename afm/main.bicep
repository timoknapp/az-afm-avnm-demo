@description('Admin username for the servers')
param adminUsername string = 'adminuser'

@description('Password for the admin account on the servers')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2_v3'

resource virtualWan 'Microsoft.Network/virtualWans@2021-08-01' = {
  name: 'vwan-demo-${location}-001'
  location: location
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    type: 'Standard'
  }
}

resource virtualHub 'Microsoft.Network/virtualHubs@2021-08-01' = {
  name: 'rtserv-demo-${location}-001'
  location: location
  properties: {
    addressPrefix: '10.1.0.0/16'
    virtualWan: {
      id: virtualWan.id
    }
  }
}

resource hubVNetconnection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2021-08-01' = {
  parent: virtualHub
  name: 'con-demo-hub-to-spoke-001'
  dependsOn: [
    firewall
  ]
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetwork.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: false
    enableInternetSecurity: true
    routingConfiguration: {
      associatedRouteTable: {
        id: hubRouteTable.id
      }
      propagatedRouteTables: {
        labels: [
          'VNet'
        ]
        ids: [
          {
            id: hubRouteTable.id
          }
        ]
      }
    }
  }
}

resource logAnalyticsWorkspaceFirewall 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-firewall-${location}-001'
  location: location
}

resource policy 'Microsoft.Network/firewallPolicies@2022-07-01' = {
  name: 'afwp-demo-${location}-001'
  location: location
  properties: {
    threatIntelMode: 'Alert'
    insights: {
      isEnabled: true
      logAnalyticsResources: {
        defaultWorkspaceId: {
          id: logAnalyticsWorkspaceFirewall.id
        }
        workspaces: [
          {
            workspaceId: {
              id: logAnalyticsWorkspaceFirewall.id
            }
            region: location
          }
        ]
      }
      retentionDays: 14
    }
  }
}

resource diagnosticSettingsFirewall 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-firewall-${location}-001'
  scope: firewall
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 14
          enabled: true
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceFirewall.id
  }
}

resource ruleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  parent: policy
  name: 'afwpg-demo-${location}-001'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'RC-01'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'Allow-msft'
            sourceAddresses: [
              '*'
            ]
            protocols: [
              {
                port: 80
                protocolType: 'Http'
              }
              {
                port: 443
                protocolType: 'Https'
              }
            ]
            targetFqdns: [
              '*.microsoft.com'
            ]
          }
        ]
      },{
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        name: 'RC-02'
        priority: 100
        action: {
          type: 'Dnat'
        }
        rules:[
          {
            ruleType: 'NatRule'
            name: 'Allow-rdp'
            destinationAddresses: [
              firewall.properties.hubIPAddresses.publicIPs.addresses[0].address
            ]
            destinationPorts: [
              '3389'
            ]
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '*'
            ]
            translatedAddress: netInterface_workload_srv.properties.ipConfigurations[0].properties.privateIPAddress
            translatedPort: '3389'
          }
        ]
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: 'afw-demo-${location}-001'
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    hubIPAddresses: {
      publicIPs: {
        count: 1
      }
    }
    virtualHub: {
      id: virtualHub.id
    }
    firewallPolicy: {
      id: policy.id
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'vnet-spoke-${location}-001'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource subnet_Workload_SN 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: virtualNetwork
  name: 'snet-workload-${location}-001'
  properties: {
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource Workload_Srv 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'vm-workload-${location}-001'
  location: location
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
          id: netInterface_workload_srv.id
        }
      ]
    }
  }
}

resource netInterface_workload_srv 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'nic-vm-workload-${location}-001'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_Workload_SN.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: nsg_workload_srv.id
    }
  }
}

resource nsg_workload_srv 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: 'nsg-workload-srv'
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource hubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2021-08-01' = {
  parent: virtualHub
  name: 'rt-hub'
  properties: {
    routes: [
      {
        name: 'Workload-SNToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '10.0.1.0/24'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
      {
        name: 'InternetToFirewall'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: firewall.id
      }
    ]
    labels: [
      'VNet'
    ]
  }
}

// Azure Firewall Workbook

@description('The friendly name for the workbook that is used in the Gallery or Saved List.  This name must be unique within a resource group.')
param workbookDisplayName string = 'Azure Firewall Workbook'

@description('The gallery that the workbook will been shown under. Supported values include workbook, tsg, etc. Usually, this is \'workbook\'')
param workbookType string = 'workbook'

@description('The id of resource instance to which the workbook will be associated')
param workbookSourceId string = 'Azure Monitor'

@description('The unique guid for this workbook instance')
param workbookId string = newGuid()

resource workbookId_resource 'microsoft.insights/workbooks@2021-03-08' = {
  name: workbookId
  location: resourceGroup().location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: string(loadJsonContent('Azure_Firewall_Workbook.json'))
    version: '1.0'
    sourceId: workbookSourceId
    category: workbookType
  }
}


