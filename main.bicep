param env string = 'prod'
param location_abbreviation string ='ne'
param location string ='northeurope'
param resource_number string='02'
param objectId string ='05f9dbf8-3e61-43a5-8ae6-a57ece430f3e'
@secure()
param geoapiSecret string = ''

// module eventgridModule './eventgrid.bicep' = {
//   name: 'storageDeployment'
//   params: {
//     env: env
//     location: location
//   }
// }

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
    resource_number: '07'
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

module servicePlanModule './serviceplan.bicep' = {
  name: 'servicePlanDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
}

module logicAppModule './logicapp.bicep' = {
  name: 'logicAppDeployment'
  params: {
    env: env
    location: location
    location_abbreviation: location_abbreviation
    resource_number: resource_number
  }
  dependsOn: [
    servicePlanModule
  ]
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
