param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sffabricomnisyncpricebooks_name string = 'wf-sffabricomnisyncpricebooks_name-${suffix}'
param connections_eventhubs_id string=''
param connections_salesforce_id string=''

resource wf_sffabricomnisyncpricebooks 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sffabricomnisyncpricebooks_name
  location: location
  properties: {
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
                    Pricebook2Id: {}
                    Product2Id: {}
                    CurrencyIsoCode: {}
                    UnitPrice: {}
                    IsActive: {}
                    UseStandardPrice: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    IsArchived: {}
                    ProductSellingModelId: {}
                    UnitCost__c: {}
                  }
                }
              }
            }
          }
        }
        Condition: {
          actions: {
            Create_Product__Deleted_Price_CDC__: {
              type: 'Compose'
              inputs: {
                Operation: 'Update'
                Entity: 'Products'
                Values: '{ "SalesForceId": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'Product2Id\']}","UnitPrice": "","UnitCost": "","CurrencyKey": "","CreatedDate": "","UpdatedDate": "" }'
                CreatedDate: '@utcNow()'
                UpdatedDate: '@utcNow()'
              }
            }
            Send_CDC_delete_event: {
              runAfter: {
                Create_Product__Deleted_Price_CDC__: [
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
                  ContentData: '@base64(outputs(\'Create_Product__Deleted_Price_CDC__\'))'
                }
                path: '/@{encodeURIComponent(\'evh-omnisynccdc-prod-ne-01\')}/events'
                queries: {
                  partitionKey: '0'
                }
              }
            }
          }
          runAfter: {
            Parse_SalesForce_CDC_JSON_record: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Create_Product__Upsert_Price_CDC_: {
                runAfter: {
                  Get_PriceBookEntry_record: [
                    'Succeeded'
                  ]
                }
                type: 'Compose'
                inputs: {
                  Operation: 'Update'
                  Entity: 'Product'
                  Values: '{ "SalesForceId": "@{body(\'Get_PriceBookEntry_record\')?[\'Product2Id\']}","UnitPrice": "@{body(\'Get_PriceBookEntry_record\')[\'UnitPrice\']}","UnitCost": "@{body(\'Get_PriceBookEntry_record\')?[\'UnitCost__c\']}","CurrencyKey": "@{body(\'Get_PriceBookEntry_record\')?[\'CurrencyIsoCode\']}","CreatedDate": "@{utcNow()}","UpdatedDate": "@{body(\'Get_PriceBookEntry_record\')?[\'LastModifiedDate\']}" }'
                  CreatedDate: '@utcNow()'
                  UpdatedDate: '@utcNow()'
                }
              }
              Send_CDC_Upsert_event: {
                runAfter: {
                  Create_Product__Upsert_Price_CDC_: [
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
                    ContentData: '@base64(outputs(\'Create_Product__Upsert_Price_CDC_\'))'
                  }
                  path: '/@{encodeURIComponent(\'evh-omnisynccdc-prod-ne-01\')}/events'
                  queries: {
                    partitionKey: '0'
                  }
                }
              }
              Get_PriceBookEntry_record: {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                    }
                  }
                  method: 'get'
                  path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])))}'
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'ChangeEventHeader\']?[\'changeType\']'
                  'DELETE'
                ]
              }
            ]
          }
          type: 'If'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        type: 'Object'
        value: {
          salesforce: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/salesforce'
            connectionId: connections_salesforce_id
            connectionName: 'salesforce'
          }
          eventhubs: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/eventhubs'
            connectionId: connections_eventhubs_id
            connectionName: 'eventhubs'
          }
        }
      }
    }
  }
}

output wf_sffabricomnisyncpricebooks_callbackurl string = listCallbackURL('${wf_sffabricomnisyncpricebooks.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
