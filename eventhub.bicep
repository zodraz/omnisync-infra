param evhns_omnisync_name string = 'evhns-omnisync-${suffix}'
param eh_omnisync_name string = 'eh-omnisync-${suffix}'
param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'

resource evhns_omnisync 'Microsoft.EventHub/namespaces@2024-05-01-preview' = {
  name: evhns_omnisync_name
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    geoDataReplication: {
      maxReplicationLagDurationInSeconds: 0
      locations: [
        {
          locationName: location
          roleType: 'Primary'
        }
      ]
    }
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    zoneRedundant: true
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    kafkaEnabled: true
  }
}

resource evhns_omnisync_rootManageSharedAccessKey 'Microsoft.EventHub/namespaces/authorizationrules@2024-05-01-preview' = {
  parent: evhns_omnisync
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

resource evh_omnisynccdc 'Microsoft.EventHub/namespaces/eventhubs@2024-05-01-preview' = {
  parent: evhns_omnisync
  name: eh_omnisync_name
  properties: {
    messageTimestampDescription: {
      timestampType: 'LogAppend'
    }
    retentionDescription: {
      cleanupPolicy: 'Delete'
      retentionTimeInHours: 1
    }
    messageRetentionInDays: 1
    partitionCount: 1
    status: 'Active'
  }
}

resource evhns_omnisync_networkRuleSets 'Microsoft.EventHub/namespaces/networkrulesets@2024-05-01-preview' = {
  parent: evhns_omnisync
  name: 'default'
  properties: {
    publicNetworkAccess: 'Enabled'
    defaultAction: 'Allow'
    virtualNetworkRules: []
    ipRules: []
    trustedServiceAccessEnabled: false
  }
}

resource evh_omnisynccdc_eventHubrootKey 'Microsoft.EventHub/namespaces/eventhubs/authorizationrules@2024-05-01-preview' = {
  parent: evh_omnisynccdc
  name: 'EventHubrootKey'
  properties: {
    rights: [
      'Manage'
      'Listen'
      'Send'
    ]
  }
}
