// general

@description('Location for all resources.')
param location string = resourceGroup().location

// sql parameters

@description('The SQL Server name')
param dbServerName string = 'svr99'

@description('Flag indicating whether server exists. (temp param until a proper way to check wehtehr resource exists)')
param serverExists bool = false

@description('The database name')
param dbName string = 'db'

@description('The admin user of the SQL Server')
param sqlAdministratorLogin string = 'SqlUser'

@description('The password of the admin user of the SQL Server')
@secure()
param sqlAdministratorLoginPassword string = '***'


// web Api

param planNameApi string
param appNameApi string

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
param skuNameApi string = 'S1'

@description('Describes plan\'s instance count')
@minValue(1)
param skuCapacityApi int = 1

// web UI

param planNameUI string
param appNameUI string

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
param skuNameUI string = 'S1'

@description('Describes plan\'s instance count')
@minValue(1)
param skuCapacityUI int = 1


module sql 'sql/azuredeploy.bicep' = {
  name: 'sql'
  params: {
    location: location
    dbServerName: dbServerName
    serverExists: serverExists
    dbName: dbName
    sqlAdministratorLogin: sqlAdministratorLogin
    sqlAdministratorLoginPassword: sqlAdministratorLoginPassword
  }
}

module webappApi 'webapp/azuredeploy.bicep' = {
  name: 'webapp-api'
  params: {
    location: location
    planName: planNameApi
    appName: appNameApi
    skuName: skuNameApi
    skuCapacity: skuCapacityApi
    setSystemIdentity: 'on'
  }
}


module webappUI 'webapp/azuredeploy.bicep' = {
  name: 'webapp-ui'
  params: {
    location: location
    planName: planNameUI
    appName: appNameUI
    skuName: skuNameUI
    skuCapacity: skuCapacityUI
  }
}

