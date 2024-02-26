param adminUsername string = 'tim'

@secure()
param adminPassword string = '' // Updated placeholder password

param vmSize string = 'Standard_B2ms'
param virtualNetworkId string = '/subscriptions/fc8d795a-57cf-4416-acb5-c4de5461a4bc/resourceGroups/az801-rg/providers/Microsoft.Network/virtualNetworks/az801-vnet'
param subnetName string = 'domain'
param location string = 'eastus'

var vmNames = [
  'mem1'
  'mem2'
  'mem3'
]

resource nics 'Microsoft.Network/networkInterfaces@2020-06-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${virtualNetworkId}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}]

resource vms 'Microsoft.Compute/virtualMachines@2021-07-01' = [for (vmName, i) in vmNames: {
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
          id: nics[i].id
        }
      ]
    }
    storageProfile: {
      // Specify the storage profile based on your requirements
    }
  }
  dependsOn: [
    nics
  ]
}]
