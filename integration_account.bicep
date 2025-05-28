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

resource ia_omnisync_d365_account_to_customer 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'D365AccountToCustomer'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/D365AccountToCustomer.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_d365_currency_to_currency 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'D365CurrencyToCurrency'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/D365CurrencyToCurrency.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_d365_product_to_product 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'D365ProductToProduct'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/D365ProductToProduct.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_d365_retailstore_to_store 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'D365RetailStoreToStore'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/D365RetailStoreToStore.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_account_to_customer 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceAccountToCustomer'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceAccountToCustomer.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_account_to_customer_update 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceAccountToCustomerUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceAccountToCustomerUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_product2_to_product_update 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceProduct2ToProductUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceProduct2ToProductUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_product2_to_product 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceProduct2ToProduct'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceProduct2ToProduct.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_currencytype_to_currency 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceCurrencyTypeToCurrency'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceCurrencyTypeToCurrency.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_salesforce_currencytype_to_currency_update 'Microsoft.Logic/integrationAccounts/maps@2019-05-01' = {
  parent: ia_omnisync
  name: 'SalesForceCurrencyTypeToCurrencyUpdate'
  properties: {
    mapType: 'Liquid'
    content: loadTextContent('artifacts/maps/SalesForceCurrencyTypeToCurrencyUpdate.liquid')
    contentType: 'text/plain'
  }
}

resource ia_omnisync_retailstore_deleted_event 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'RetailStoreDeletedEvent'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'urn:sobject.enterprise.soap.sforce.com'
    content: loadTextContent('artifacts/schemas/RetailStoreDeletedEvent.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_retailstore 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'RetailStore'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'urn:sobject.enterprise.soap.sforce.com'
    content: loadTextContent('artifacts/schemas/RetailStore.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_id 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'ID'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'urn:enterprise.soap.sforce.com'
    content: loadTextContent('artifacts/schemas/ID.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_outbound_retailstore 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
  parent: ia_omnisync
  name: 'OutboundRetailStore'
  properties: {
    schemaType: 'Xml'
    targetNamespace: 'http://soap.sforce.com/2005/09/outbound'
    content: loadTextContent('artifacts/schemas/OutboundRetailStore.xsd')
    contentType: 'application/xml'
    }
}

resource ia_omnisync_outbound_retailstore_deleted_event 'Microsoft.Logic/integrationAccounts/schemas@2019-05-01' = {
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
