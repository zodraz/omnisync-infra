param location string ='northeurope'
param connections_salesforce_name string = 'salesforce'

resource connections_salesforce 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_salesforce_name
  location: location
  properties: {
    displayName: 'fakeuser@omnisync.com'
    customParameterValues: {}
    nonSecretParameterValues: {
      salesforceApiVersion: 'v58'
      'token:LoginUri': 'https://login.${connections_salesforce_name}.com'
    }
    api: {
      name: connections_salesforce_name
      displayName: 'Salesforce'
      description: 'The Salesforce Connector provides an API to work with Salesforce objects.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/releases/v1.0.1732/1.0.1732.4070/${connections_salesforce_name}/icon.png'
      brandColor: '#1EB8EB'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_salesforce_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().id}/providers/Microsoft.Web/connections/${connections_salesforce_name}/extensions/proxy/testconnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

output connections_salesforce_id string = connections_salesforce.id
