param diskName string = 'twaz801shd1' // Your specified disk name
param location string = resourceGroup().location
param diskSizeGB int = 256 // Your specified disk size (GB)

resource sharedDisk 'Microsoft.Compute/disks@2023-03-01' = {
  name: diskName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
      diskSizeGB: diskSizeGB
    }
    maxShares: 3 // Adjust if needed for your cluster
  }
}
