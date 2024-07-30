@description('Specifies the name of the key vault.')
param keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForDeployment bool = true

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
@allowed([
  true
  false
])
param enabledForDiskEncryption bool = true

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
@allowed([
  true
  false
])
param enabledForTemplateDeployment bool = true

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string = 'NA'

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'all'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'all'
]

@description('Specifies the permissions to certificates in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param certPermissions array = [
  'all'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

resource keyVault 'Microsoft.KeyVault/vaults@2018-02-14' = {
  name: keyVaultName
  location: location
  tags: {
    displayName: 'KeyVault'
  }
  properties: {
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: true
    tenantId: tenantId
    accessPolicies: (!empty(objectId) && objectId != 'NA') ? [
      {
        objectId: objectId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
          certificates: certPermissions
        }
      }
    ] : []
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      value: {
        defaultAction: 'Allow'
        bypass: 'AzureServices'
      }
    }
  }
}
