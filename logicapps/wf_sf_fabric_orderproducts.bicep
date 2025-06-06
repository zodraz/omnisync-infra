param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_orderproducts_name string = 'wf-sf-fabric-omnisync-orderproducts-${suffix}'
param connections_eventhubs_id string=''
param connections_salesforce_id string=''

resource wf_sf_fabric_omnisync_orderproducts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_orderproducts_name
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
        When_a_HTTP_request_is_received: {
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
        Send__CDC_event: {
          runAfter: {
            Create_CDC_SalesOrder_record: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'eventhubs\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              ContentData: '@base64(outputs(\'Create_CDC_SalesOrder_record\'))'
            }
            path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
            queries: {
              partitionKey: '0'
            }
          }
        }
        Parse_SalesForce_CDC_JSON_record: {
          runAfter: {}
          type: 'ParseJson'
          inputs: {
            content: '@triggerBody().data.message'
            schema: {
              type: 'object'
              properties: {
                replayId: {
                  type: 'integer'
                }
                payload: {
                  type: 'object'
                  properties: {
                    ChangeEventHeader: {
                      type: 'object'
                      properties: {
                        entityName: {
                          type: 'string'
                        }
                        recordIds: {
                          type: 'array'
                          items: {
                            type: 'string'
                          }
                        }
                        changeType: {
                          type: 'string'
                        }
                        changeOrigin: {
                          type: 'string'
                        }
                        transactionKey: {
                          type: 'string'
                        }
                        sequenceNumber: {
                          type: 'integer'
                        }
                        commitTimestamp: {
                          type: 'integer'
                        }
                        commitNumber: {
                          type: 'integer'
                        }
                        commitUser: {
                          type: 'string'
                        }
                        nulledFields: {
                          type: 'array'
                        }
                        diffFields: {
                          type: 'array'
                        }
                        changedFields: {
                          type: 'array'
                        }
                      }
                    }
                    Product2Id: {}
                    OrderId: {}
                    PricebookEntryId: {}
                    OriginalOrderItemId: {}
                    QuoteLineItemId: {}
                    AvailableQuantity: {}
                    Quantity: {}
                    CurrencyIsoCode: {}
                    UnitPrice: {}
                    ListPrice: {}
                    ServiceDate: {}
                    EndDate: {}
                    Description: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    OrderItemNumber: {}
                    QuantityUnitOfMeasureId: {}
                    CostPrice__c: {}
                  }
                }
              }
            }
          }
        }
        Create_CDC_SalesOrder_record: {
          runAfter: {
            Get_Order: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: {
            Operation: '@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'ChangeEventHeader\']?[\'changeType\']}'
            Entity: 'SalesOrders'
            Values: '{ "SalesForceId": "@{first(body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])}","DateKey": "@{body(\'Get_Order\')[\'EffectiveDate\']}","StoreKey": "@{body(\'Get_Order\')[\'RetailStore__c\']}","ProductKey": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'Product2Id\']}","CurrencyKey": "@{body(\'Get_Order\')[\'CurrencyIsoCode\']}","CustomerKey": "@{body(\'Get_Order\')[\'AccountId\']}","SalesOrderNumber": "@{body(\'Get_Order\')[\'OrderNumber\']}","SalesOrderLineNumber": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'OrderItemLineNumber__c\']}","SalesQuantity": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'Quantity\']}","UnitCost": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'CostPrice__c\']}","UnitPrice": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'UnitPrice\']}","CreatedDate": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'CreatedDate\']}","UpdatedDate": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'LastModifiedDate\']}"}'
            CreatedDate: '@utcNow()'
            UpdatedDate: '@utcNow()'
          }
        }
        Get_Order: {
          runAfter: {
            Parse_SalesForce_CDC_JSON_record: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'OrderId\']))}'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          eventhubs: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/eventhubs'
            connectionId: connections_eventhubs_id
            connectionName: 'eventhubs'
          }
          salesforce: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/salesforce'
            connectionId: connections_salesforce_id
            connectionName: 'salesforce'
          }
        }
      }
    }
  }
}

output wf_sf_fabric_omnisync_orderproducts_callbackurl string = listCallbackURL('${wf_sf_fabric_omnisync_orderproducts.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
