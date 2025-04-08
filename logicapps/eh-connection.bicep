param location string ='northeurope'
param connections_eventhubs_name string = 'eventhubs'

resource connections_eventhubs 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_eventhubs_name
  location: location
  properties: {
    displayName: connections_eventhubs_name
    customParameterValues: {}
    api: {
      name: connections_eventhubs_name
      displayName: 'Event Hubs'
      description: 'Connect to Azure Event Hubs to send and receive events.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/releases/v1.0.1718/1.0.1718.3946/${connections_eventhubs_name}/icon.png'
      brandColor: '#c4d5ff'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_eventhubs_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

output connections_eventhubs_id string = connections_eventhubs.id
