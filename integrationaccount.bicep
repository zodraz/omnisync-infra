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
    contentType: 'text/plain'
  }
}

resource ia_omnisync_AccountToCustomerUpdate 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'AccountToCustomerUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/AccountToCustomerUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_Product2ToProductUpdate 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'Product2ToProductUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/Product2ToProductUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_Product2ToProduct 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'Product2ToProduct'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/Product2ToProduct.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_CurrencyTypeToCurrency 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'CurrencyTypeToCurrency'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/CurrencyTypeToCurrency.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_CurrencyTypeToCurrencyUpdate 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'CurrencyTypeToCurrencyUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/CurrencyTypeToCurrencyUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_RetailStoreDeletedEvent 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'RetailStoreDeletedEvent'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'urn:sobject.enterprise.soap.sforce.com'
    content: loadTextContent('artifacts/schemas/RetailStoreDeletedEvent.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_ID 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'ID'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'urn:enterprise.soap.sforce.com'
    content: loadTextContent('artifacts/schemas/ID.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_OutboundRetailStoreDeletedEvent 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'OutboundRetailStoreDeletedEvent'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'http://soap.sforce.com/2005/09/outbound'
    content: loadTextContent('artifacts/schemas/OutboundRetailStoreDeletedEvent.xsd')
    contentType: 'application/xml'
    }
}

output ia_omnisync_id string = ia_omnisync.id
