param evgt_omnisyncsalesforce_name string = 'evgt-omnisyncsalesforce-${suffix}'
param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param topics_evgt_omnisyncsalesforce_webhook_url_account string = 'https://localhost'
param topics_evgt_omnisyncsalesforce_webhook_url_pricebookentry string = 'https://localhost'
param topics_evgt_omnisyncsalesforce_webhook_url_product string = 'https://localhost'
param topics_evgt_omnisyncsalesforce_webhook_url_orderitem string = 'https://localhost'
param topics_evgt_omnisyncsalesforce_webhook_url_orderitem_deleted string = 'https://localhost'

resource evgt_omnisyncsalesforce 'Microsoft.EventGrid/topics@2025-02-15' = {
  name: evgt_omnisyncsalesforce_name
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    minimumTlsVersionAllowed: '1.2'
    inputSchema: 'CloudEventSchemaV1_0'
    publicNetworkAccess: 'Enabled'
    inboundIpRules: []
    disableLocalAuth: false
    // dataResidencyBoundary: 'Withinlocation'
  }
}

resource evgs_omnisyncsalesforceaccounts 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: evgt_omnisyncsalesforce
  name: 'evgs-omnisyncsalesforceaccounts-${suffix}'
  properties: {
    destination: {
      properties: {
        endpointUrl: topics_evgt_omnisyncsalesforce_webhook_url_account
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      subjectBeginsWith: 'Account'
      enableAdvancedFilteringOnArrays: false
    }
    labels: []
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

resource evgs_omnisyncsalesforcepricebooks 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: evgt_omnisyncsalesforce
  name: 'evgs-omnisyncsalesforcepricebooks-${suffix}'
  properties: {
    destination: {
      properties: {
        endpointUrl: topics_evgt_omnisyncsalesforce_webhook_url_pricebookentry
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      subjectBeginsWith: 'PricebookEntry'
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

resource evgs_omnisyncsalesforceproducts 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: evgt_omnisyncsalesforce
  name: 'evgs-omnisyncsalesforceproducts-${suffix}'
  properties: {
    destination: {
      properties: {
        endpointUrl: topics_evgt_omnisyncsalesforce_webhook_url_product
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      subjectBeginsWith: 'Product2'
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

resource evgs_omnisyncsalesforcesalesorders 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: evgt_omnisyncsalesforce
  name: 'evgs-omnisyncsalesforcesalesorders-${suffix}'
  properties: {
    destination: {
      properties: {
        endpointUrl: topics_evgt_omnisyncsalesforce_webhook_url_orderitem
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      subjectBeginsWith: 'OrderItem'
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

resource evgs_omnisyncsalesforcesalesordersdelete 'Microsoft.EventGrid/topics/eventSubscriptions@2025-02-15' = {
  parent: evgt_omnisyncsalesforce
  name: 'evgs-omnisyncsalesforcesalesordersdelete-${suffix}'
  properties: {
    destination: {
      properties: {
        endpointUrl: topics_evgt_omnisyncsalesforce_webhook_url_orderitem_deleted
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'WebHook'
    }
    filter: {
      subjectBeginsWith: '"OrderProductDeleted'
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'CloudEventSchemaV1_0'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}
