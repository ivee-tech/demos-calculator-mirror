param location string = resourceGroup().location
param jumpBoxVMName string
param vnetName string
param subnetName string
@secure()
param localAdminPassword string

resource vnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: subnetName
  parent: vnet
}

module nsg './modules/Microsoft.Network/networkSecurityGroups/deploy.bicep' =  {
  name: '${uniqueString(deployment().name, vnetName, subnetName)}-nsg-${location}'
  params: {
    name: '${vnetName}-${subnet.name}-nsg-${location}'
    location: location
    }
}

module virtualMachineWin './modules/Microsoft.Compute/virtual-machine/main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-${jumpBoxVMName}'
  params: {
    // Required parameters
    adminUsername: 'localAdminUser'
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: subnet.id
            pipconfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
          }
        ]
        nicSuffix: '-nic-01'
        networkSecurityGroupResourceId: nsg.outputs.resourceId
      }
    ]
    osDisk: {
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v2'
    // Non-required parameters
    adminPassword: localAdminPassword
    enableDefaultTelemetry: false
    location: location
    name: jumpBoxVMName
    encryptionAtHost: false
  }
  dependsOn: [
    nsg
  ]
}
