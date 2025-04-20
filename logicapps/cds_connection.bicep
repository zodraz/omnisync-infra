param location string ='northeurope'
param connections_cds_name string = 'commondataservice'

resource connections_cds 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_cds_name
  location: location
  properties: {
    displayName: 'fakeuser@omnisync.com'
    customParameterValues: {}
    nonSecretParameterValues: {
      'token:grantType': 'code'
    }
    api: {
      name: 'commondataservice'
      displayName: 'Microsoft Dataverse'
      description: 'Provides access to the environment database in Microsoft Dataverse.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/releases/v1.0.1735/1.0.1735.4106/commondataservice/icon-la.png'
      brandColor: '#637080'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_cds_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: []
  }
}

output connections_cds_name_id string = connections_cds.id
