param location string ='northeurope'
param connections_sql_name string = 'sql'

resource connections_sql 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_sql_name
  location: location
  properties: {
    displayName: 'Fabric'
    customParameterValues: {}
    api: {
      name: connections_sql_name
      displayName: 'SQL Server'
      description: 'Microsoft SQL Server is a relational database management system developed by Microsoft. Connect to SQL Server to manage data. You can perform various actions such as create, update, get, and delete on rows in a table.'
      iconUri: 'https://conn-afd-prod-endpoint-bmc9bqahasf3grgk.b01.azurefd.net/releases/v1.0.1746/1.0.1746.4174/${connections_sql_name}/icon.png'
      brandColor: '#ba141a'
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/${connections_sql_name}'
      type: 'Microsoft.Web/locations/managedApis'
    }
    testLinks: [
      {
        requestUri: 'https://management.azure.com:443/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().id}/providers/Microsoft.Web/connections/${connections_sql_name}/extensions/proxy/testconnection?api-version=2016-06-01'
        method: 'get'
      }
    ]
  }
}

output connections_sql_id string = connections_sql.id
