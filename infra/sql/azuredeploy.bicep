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

@description('Location for all resources.')
param location string = resourceGroup().location

resource dbServerName_resource 'Microsoft.Sql/servers@2014-04-01' = if(!serverExists) {
  name: dbServerName
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource dbServerName_dbName 'Microsoft.Sql/servers/databases@2015-01-01' = {
  parent: dbServerName_resource
  name: '${dbName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: 'Basic'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}

resource dbServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01' = {
  parent: dbServerName_resource
  location: location
  name: 'AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output sqlSvrFqdn string = dbServerName_resource.properties.fullyQualifiedDomainName
