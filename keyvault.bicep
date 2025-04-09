param kv_omnisync_name string = 'kv-omnisync-${suffix}'
param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string
@secure()
param geoapiSecret string

resource kv_omnisync 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: kv_omnisync_name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: objectId
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'GetRotationPolicy'
            'SetRotationPolicy'
            'Rotate'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
    // enablePurgeProtection: null
    vaultUri: 'https://${kv_omnisync_name}${environment().suffixes.keyvaultDns}/'
    publicNetworkAccess: 'Enabled'
  }
}

resource kv_omnisync_geoapi_secret 'Microsoft.KeyVault/vaults/secrets@2024-12-01-preview' = {
  parent: kv_omnisync
  name: 'geoapi-secret'
  properties: {
    value: geoapiSecret
    attributes: {
      enabled: true
    }
  }
}

output location string = location
output name string = kv_omnisync.name
output resourceGroupName string = resourceGroup().name
output resourceId string = kv_omnisync.id
