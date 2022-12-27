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
