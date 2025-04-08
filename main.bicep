param env string = 'prod'
param location_abbreviation string ='ne'
param location string ='northeurope'
param resource_number string='03'
param objectId string ='05f9dbf8-3e61-43a5-8ae6-a57ece430f3e'
@secure()
param geoapiSecret string = ''

module eventHubModule './eventhub.bicep' = {
  name: 'eventHubDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module keyVaultModule './keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    objectId: objectId
    geoapiSecret: geoapiSecret
    resource_number: '08'
  }
}

module storageAccountModule './storageaccount.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

// module servicePlanModule './serviceplan.bicep' = {
//   name: 'servicePlanDeployment'
//   params: {
//     env: env
//     location: location
//     location_abbreviation: location_abbreviation
//     resource_number: resource_number
//   }
// }

module integrationAccountModule './integrationAccount.bicep' = {
  name: 'integrationAccountDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

// module logicAppModule './logicapp.bicep' = {
//   name: 'logicAppDeployment'
//   params: {
//     env: env
//     location: location
//     location_abbreviation: location_abbreviation
//     resource_number: resource_number
//   }
//   dependsOn: [
//     integrationAccountModule
//   ]
// }
module logicAppsEhConnectionModule './logicapps/eh-connection.bicep' = {
  name: 'logicAppsEhConnectioneployment'
  params: {
    location: location
  }
}

module logicAppsSfConnectionModule './logicapps/sf-connection.bicep' = {
  name: 'logicAppsSfConnectioneployment'
  params: {
    location: location
  }
}

module logicAppsSfFabricAccountsModule './logicapps/wf-sf-fabric-accounts.bicep' = {
  name: 'logicAppsSfFabricAccountsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
  }
}

module logicAppsSfFabricCurrencyTypeInsertModule './logicapps/wf-sf-fabric-currencytype-insert.bicep' = {
  name: 'logicAppsSfFabricCurrencyTypeInsertDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logicAppsSfFabricCurrencyTypeUpdateModule './logicapps/wf-sf-fabric-currencytype-update.bicep' = {
  name: 'logicAppsSfFabricCurrencyTypeUpdateDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logicAppsSfFabricOrderDetailsModule './logicapps/wf-sf-fabric-orderdetails.bicep' = {
  name: 'logicAppsSfFabricOrderDetailsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logicAppsSfFabricPriceBooksModule './logicapps/wf-sf-fabric-pricebooks.bicep' = {
  name: 'logicAppsSfFabricPriceBooksDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logicAppsSfFabricProductsModule './logicapps/wf-sf-fabric-products.bicep' = {
  name: 'logicAppsSfFabricProductsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
  }
}

module logicAppsSfFabricRetailStoreDeletedModule './logicapps/wf-sf-fabric-retailstore-delete.bicep' = {
  name: 'logicAppsSfFabricRetailStoreDeletedDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
  }
}

module logicAppsSfFabricRetailStoreInsertModule './logicapps/wf-sf-fabric-retailstore-insert.bicep' = {
  name: 'logicAppsSfFabricRetailStoreInsertDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logicAppsSfFabricRetailStoreUpdateModule './logicapps/wf-sf-fabric-retailstore-update.bicep' = {
  name: 'logicAppsSfFabricRetailStoreUpdateDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integrationAccountModule.outputs.ia_omnisync_id
    connections_eventhubs_id: logicAppsEhConnectionModule.outputs.connections_eventhubs_id
    connections_salesforce_id: logicAppsSfConnectionModule.outputs.connections_salesforce_id
  }
}

module logAnalyticsModule './loganalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module applicationInsightsModule './applicationinsights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module eventgridModule './eventgrid.bicep' = {
  name: 'storageDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    topics_evgt_omnisyncsalesforce_webhook_url_account:logicAppsSfFabricAccountsModule.outputs.wf_sffabricomnisyncaccounts_callbackurl
    topics_evgt_omnisyncsalesforce_webhook_url_product:logicAppsSfFabricProductsModule.outputs.wf_sffabricomnisyncproducts_callbackurl
    topics_evgt_omnisyncsalesforce_webhook_url_pricebookentry: logicAppsSfFabricPriceBooksModule.outputs.wf_sffabricomnisyncpricebooks_callbackurl
    topics_evgt_omnisyncsalesforce_webhook_url_orderitem: logicAppsSfFabricOrderDetailsModule.outputs.wf_sffabricomnisyncorderdetails_callbackurl
  }
}
