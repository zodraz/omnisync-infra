param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_retailstores_update_name string = 'wf-sf-d365-omnisyncinc-retailstores-update-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_retailstores_update 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_retailstores_update_name
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_row_is_added,_modified_or_deleted': {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            body: {
              entityname: 'salesorderdetail'
              message: 7
              scope: 4
              version: 1
              url: '@listCallbackUrl()'
            }
            headers: {
              organization: 'https://org58211bdf.crm4.dynamics.com'
              Consistency: 'Strong'
              catalog: 'all'
              category: 'all'
            }
            path: '/api/data/v9.1/callbackregistrations'
          }
        }
      }
      actions: {
        Get_Order: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            method: 'get'
            headers: {
              prefer: 'odata.include-annotations=*'
              accept: 'application/json;odata.metadata=full'
              organization: 'https://org58211bdf.crm4.dynamics.com'
            }
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'_salesorderid_value\']))})'
          }
        }
        Create_CDC_SalesOrder_record: {
          runAfter: {
            Get_Product: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '@{triggerBody()?[\'modifiedon\']}{\n  "Operation": "@{triggerBody()?[\'SdkMessage\']}",\n  "Entity": "SalesOrders",\n  "Values": "{ \\"D365Id\\": \\"@{triggerBody()?[\'ItemInternalId\']}\\",\\"DateKey\\": \\"@{body(\'Get_Order\')?[\'requestdeliveryby\']}\\",\\"StoreKey\\": \\"@{body(\'Get_Order\')?[\'_cr989_retailstore_value\']}\\",\\"ProductKey\\": \\"@{triggerBody()?[\'_productid_value\']}\\",\\"CurrencyKey\\": \\"@{body(\'Get_Order\')?[\'_transactioncurrencyid_value\']}\\",\\"CustomerKey\\": \\"@{body(\'Get_Order\')?[\'_customerid_value\']}\\",\\"SalesOrderNumber\\": \\"@{body(\'Get_Order\')?[\'ordernumber\']}\\",\\"SalesOrderLineNumber\\": \\"@{triggerBody()?[\'sequencenumber\']}\\",\\"SalesQuantity\\": \\"@{triggerBody()?[\'quantity\']}\\",\\"UnitCost\\": \\"@{body(\'Get_Product\')?[\'standardcost\']}\\",\\"UnitPrice\\": \\"@{body(\'Get_Product\')?[\'price\']}\\",\\"CreatedDate\\": \\"@{triggerBody()?[\'createdon\']}\\",\\"UpdatedDate\\": \\"@{triggerBody()?[\'modifiedon\']}\\"}",\n  "CreatedDate": @{utcNow()},\n  "UpdatedDate": @{utcNow()}\n}'
        }
        Get_Product: {
          runAfter: {
            Get_Order: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            method: 'get'
            headers: {
              prefer: 'odata.include-annotations=*'
              accept: 'application/json;odata.metadata=full'
              organization: 'https://org58211bdf.crm4.dynamics.com'
            }
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'products\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'_productid_value\']))})'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          commondataservice: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/commondataservice'
            connectionId: connections_cds_id
            connectionName: 'commondataservice'
          }
          salesforce: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/salesforce'
            connectionId: connections_salesforce_id
            connectionName: 'salesforce'
          }
          sql: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
            connectionId: connections_sql_id
            connectionName: 'sql'
          }
        }
      }
    }
  }
}
