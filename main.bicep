param env string = 'prod'
param location_abbreviation string ='ne'
param location string ='northeurope'
param resource_number string='01'
param kv_resource_number string='11'
param st_resource_number string='04'
param object_id string ='05f9dbf8-3e61-43a5-8ae6-a57ece430f3e'
@secure()
param geo_api_secret string = ''
param d365_organization string=''
param integration_user string=''
param database string=''
@secure()
param sql_connection_string string=''

module event_hub_module './event_hub.bicep' = {
  name: 'eventHubDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module key_vault_module './key_vault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    objectId: object_id
    geoapiSecret: geo_api_secret
    resource_number: kv_resource_number
  }
}

module storage_account_module './storage_account.bicep' = {
  name: 'storageAccountDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: st_resource_number
  }
}

// module servicePlanModule './service_plan.bicep' = {
//   name: 'servicePlanDeployment'
//   params: {
//     env: env
//     location: location
//     location_abbreviation: location_abbreviation
//     resource_number: resource_number
//   }
// }

module integration_account_module './integration_account.bicep' = {
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

module logicapps_cds_connection_module './logicapps/cds_connection.bicep' = {
  name: 'logicAppsCdsConnectionDeployment'
  params: {
    location: location
  }
}
module logicapps_eh_connection_module './logicapps/eh_connection.bicep' = {
  name: 'logicAppsEhConnectionDeployment'
  params: {
    location: location
  }
}

module logicapps_sf_connection_module './logicapps/sf_connection.bicep' = {
  name: 'logicAppsSfConnectionDeployment'
  params: {
    location: location
  }
}

module logicapps_sql_connection_module './logicapps/sql_connection.bicep' = {
  name: 'logicAppsSqlConnectionDeployment'
  params: {
    location: location
  }
}

// // module logicapps_d365_fabric_orderproducts_module './logicapps/wf_d365_fabric_orderproducts.bicep' = {
// //   name: 'logicAppsD365FabricOrderProductsDeployment'
// //   params: {
// //     env: env
// //     location: location
// //     location_abbreviation: location_abbreviation
// //     resource_number: resource_number
// //     connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
// //     connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id
// //   }
// // }

module logicapps_d365_sf_accounts_delete_module './logicapps/wf_d365_accounts_delete.bicep' = {
  name: 'logicAppsD365AccountsDeleteDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
    connections_sql_id: logicapps_sql_connection_module.outputs.connections_sql_id
    connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id
    d365_organization: d365_organization
    integration_user: integration_user
    database: database
    sql_connection_string: sql_connection_string
  }
}

module logicapps_d365_sf_accounts_insert_module './logicapps/wf_d365_accounts_insert.bicep' = {
  name: 'logicAppsD365AccountsInsertDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
    connections_sql_id: logicapps_sql_connection_module.outputs.connections_sql_id
    connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id
    d365_organization: d365_organization
    integration_user: integration_user
    database: database
    sql_connection_string: sql_connection_string
  }
}

module logicapps_d365_sf_accounts_update_module './logicapps/wf_d365_accounts_update.bicep' = {
  name: 'logicAppsD365AccountsUpdateDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
    connections_sql_id: logicapps_sql_connection_module.outputs.connections_sql_id
    connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id
    d365_organization: d365_organization
    integration_user: integration_user
    database: database
    sql_connection_string: sql_connection_string
  }
}

// module logicapps_d365_sf_accounts_module './logicapps/wf_d365_fabric_orderproducts.bicep' = {
//   name: 'logicAppsD365FabricOrderProductsDeployment'
//   params: {
//     env: env
//     location: location
//     location_abbreviation: location_abbreviation
//     resource_number: resource_number
//     // ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
//     // connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
//     // connections_sql_id: logicapps_sql_connection_module.outputs.connections_sql_id
//     // connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id
//     // d365_organization: d365_organization
//     // integration_user: integration_user
//     // database: database
//     // sql_connection_string: sql_connection_string
//   }
// }

module logicapps_sf_d365_accounts_module './logicapps/wf_sf_d365_accounts.bicep' = {
  name: 'logicAppsSfD365AccountsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
    connections_sql_id: logicapps_sql_connection_module.outputs.connections_sql_id
    connections_cds_id: logicapps_cds_connection_module.outputs.connections_cds_name_id

  }
}

module logicapps_sf_fabric_accounts_module './logicapps/wf_sf_fabric_accounts.bicep' = {
  name: 'logicAppsSfFabricAccountsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
  }
}

module logicapps_sf_fabric_currencytype_insert_module './logicapps/wf_sf_fabric_currencytype_insert.bicep' = {
  name: 'logicAppsSfFabricCurrencyTypeInsertDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module logicapps_sf_fabric_currencytype_update_module './logicapps/wf_sf_fabric_currencytype_update.bicep' = {
  name: 'logicAppsSfFabricCurrencyTypeUpdateDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module logicapps_sf_fabric_orderproducts_module './logicapps/wf_sf_fabric_orderproducts.bicep' = {
  name: 'logicAppsSfFabricOrderProductsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module logicapps_sf_fabric_pricebooks_module './logicapps/wf_sf_fabric_pricebooks.bicep' = {
  name: 'logicAppsSfFabricPriceBooksDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module logicapps_sf_fabric_products_module './logicapps/wf_sf_fabric_products.bicep' = {
  name: 'logicAppsSfFabricProductsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
  }
}

module logicapps_sf_fabric_retailstore_delete_module './logicapps/wf_sf_fabric_retailstore_delete.bicep' = {
  name: 'logicAppsSfFabricRetailStoreDeleteDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
  }
}

module logicapps_sf_fabric_retailstore_insert_module './logicapps/wf_sf_fabric_retailstore_insert.bicep' = {
  name: 'logicAppsSfFabricRetailStoreInsertDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module logicapps_sf_fabric_retailstore_update_module './logicapps/wf_sf_fabric_retailstore_update.bicep' = {
  name: 'logicAppsSfFabricRetailStoreUpdateDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    ia_omnisync_id: integration_account_module.outputs.ia_omnisync_id
    connections_eventhubs_id: logicapps_eh_connection_module.outputs.connections_eventhubs_id
    connections_salesforce_id: logicapps_sf_connection_module.outputs.connections_salesforce_id
  }
}

module log_analytics_module './log_analytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module application_insights_module './application_insights.bicep' = {
  name: 'applicationInsightsDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module eventgrid_module './event_grid.bicep' = {
  name: 'storageDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
    topics_evgt_omnisync_salesforce_fabric_webhook_url_account:logicapps_sf_fabric_accounts_module.outputs.wf_sf_fabric_omnisync_accounts_callbackurl
    topics_evgt_omnisync_salesforce_fabric_webhook_url_product:logicapps_sf_fabric_products_module.outputs.wf_sf_fabric_omnisync_products_callbackurl
    topics_evgt_omnisync_salesforce_fabric_webhook_url_pricebookentry: logicapps_sf_fabric_pricebooks_module.outputs.wf_sf_fabric_omnisync_pricebooks_callbackurl
    topics_evgt_omnisync_salesforce_fabric_webhook_url_orderitem: logicapps_sf_fabric_orderproducts_module.outputs.wf_sf_fabric_omnisync_orderproducts_callbackurl
    topics_evgt_omnisync_salesforce_d365_webhook_url_account: logicapps_sf_d365_accounts_module.outputs.wf_sf_d365_omnisync_accounts_callbackurl
  }
}
