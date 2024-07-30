param planName string
param appName string

@description('Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param skuName string = 'S1'

@description('Describes plan\'s instance count')
@minValue(1)
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

@description('If true, set the system identity.')
@allowed([
  'on'
  'off'
])
param setSystemIdentity string = 'off' // bool = false

var hostingPlanName_var = planName
var webSiteName_var = appName
var identity_var = setSystemIdentity == 'on' ? { 
  type: 'SystemAssigned' 
} : { 
  type : 'None' 
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName_var
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2021-03-01' = {
  name: webSiteName_var
  location: location
  tags: {
    'hidden-related:${hostingPlanName.id}': 'empty'
    displayName: 'Website'
  }
  identity: identity_var
  properties: {
    name: webSiteName_var
    serverFarmId: hostingPlanName.id
  }
}

output siteUri string = webSiteName.properties.hostNames[0]
