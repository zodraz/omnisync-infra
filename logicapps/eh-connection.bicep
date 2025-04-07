param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param con_eh_name string = 'con-eh-omnisync-${suffix}'

resource con_eh 'Microsoft.Web/connections@2016-06-01' = {
  name: con_eh_name
  location: location
  properties: {
    displayName: con_eh_name
    customParameterValues: {}
    api: {
      name: con_eh_name
      displayName: 'Event Hubs'
      description: 'Connect to Azure Event Hubs to send and receive events.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/releases/v1.0.1718/1.0.1718.3946/${con_eh_name}/icon.png'
      brandColor: '#c4d5ff'
      // id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${con_eh_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

output con_eh_id string = con_eh.id
