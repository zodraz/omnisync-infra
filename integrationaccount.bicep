param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param ia_omnisync_name string = 'ia-omnisync-${suffix}'


resource ia_omnisync 'Microsoft.Logic/integrationAccounts@2016-06-01' = {
  name: ia_omnisync_name
  location: location
  sku: {
    name: 'Free'
  }
  properties: {
    state: 'Enabled'
  }
}

resource ia_omnisync_AccountToCustomer 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'AccountToCustomer'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/AccountToCustomer.liquid')
    contentType: 'application/liquid'
    // fileName: 'AccountToCustomer.liquid'
  }
}

resource ia_omnisync_AccountToCustomerUpdate 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'AccountToCustomerUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/AccountToCustomer.liquid')
    contentType: 'application/liquid'
    // fileName: 'AccountToCustomer.liquid'
  }
}

output ia_omnisync_id string = ia_omnisync.id
