param adminUsername string = 'tim'
param adminPassword string = 'Agape112Agape112'
param vmSize string = 'Standard_B2ms'
param virtualNetworkId string = '/subscriptions/fc8d795a-57cf-4416-acb5-c4de5461a4bc/resourceGroups/az801-rg/providers/Microsoft.Network/virtualNetworks/az801-vnet'
param subnetName string = 'domain'
param location string = 'eastus'

var vmNames = [
'mem1'
'mem2'
'mem3'
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: virtualNetworkId
}

resource vms 'Microsoft.Compute/virtualMachines@2021-07-01' = [for vmName in vmNames: {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
      {
        id: resourceId('Microsoft.Network/networkInterfaces', '${vmName}-nic')
      }
      ]
    }
    storageProfile: {
      // Add storage profile configuration here based on the dc1 template
    }
  }
  dependsOn: [
  virtualNetwork
  ]
}]

resource nics 'Microsoft.Network/networkInterfaces@2020-06-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
    {
      name: 'ipconfig1'
      properties: {
        subnet: {
          id: '${virtualNetwork.properties.subnets[0].id}'
        }
        // Public IP configuration is omitted
      }
    }
    ]
  }
  dependsOn: [
  virtualNetwork
  ]
}]
