param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_products_name string = 'wf-sf-fabric-omnisync-products-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''

resource wf_sf_fabric_omnisync_products 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_products_name
  location: location
  properties: {
    state: 'Enabled'
    integrationAccount: {
      id: ia_omnisync_id
    }
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
        Initialize_CDC_record: {
          runAfter: {
            Parse_Initial_JSON: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'CDCRecord'
                type: 'object'
              }
            ]
          }
        }
        Parse_CDC_JSON: {
          runAfter: {
            Initialize_CDC_record: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@json(triggerBody().data.message)'
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
                          items: {
                            type: 'string'
                          }
                        }
                      }
                    }
                    Name: {}
                    Type: {}
                    RecordTypeId: {}
                    ParentId: {}
                    BillingAddress: {}
                    ShippingAddress: {
                      type: 'object'
                      properties: {
                        Street: {}
                        City: {}
                        State: {}
                        PostalCode: {}
                        Country: {}
                        Latitude: {}
                        Longitude: {}
                        GeocodeAccuracy: {}
                      }
                    }
                    Phone: {}
                    Fax: {}
                    AccountNumber: {}
                    Website: {}
                    Sic: {}
                    Industry: {}
                    AnnualRevenue: {}
                    NumberOfEmployees: {}
                    Ownership: {}
                    TickerSymbol: {}
                    Description: {}
                    Rating: {}
                    Site: {}
                    CurrencyIsoCode: {}
                    OwnerId: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    SourceSystemIdentifier: {}
                    Jigsaw: {}
                    JigsawCompanyId: {}
                    productsource: {}
                    SicDesc: {}
                    OperatingHoursId: {}
                    cgcloud__Account_Email__c: {}
                    cgcloud__Account_Number__c: {}
                    cgcloud__Account_Template__c: {}
                    cgcloud__ExternalId__c: {}
                    cgcloud__Name_2__c: {}
                    cgcloud__Number_Of_Extensions__c: {}
                    SDO_Sales_Closed_Won_Value__c: {}
                  }
                }
              }
            }
          }
        }
        Condition: {
          actions: {
            Fix_Transformated_JSON_Update: {
              runAfter: {
                Transform_JSON_To_JSON_Update: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
              inputs: '@json(replace(replace(replace(string(body(\'Transform_JSON_To_JSON_Update\')),   \'"now"\',concat(\'"\', utcNow(),\'"\')),\'\t\',\'\'),\'\r\n\',\'\'))'
            }
            Set_CDC_Update_record: {
              runAfter: {
                Fix_Transformated_JSON_Update: [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'CDCRecord'
                value: '@outputs(\'Fix_Transformated_JSON_Update\')'
              }
            }
            Transform_JSON_To_JSON_Update: {
              type: 'Liquid'
              kind: 'JsonToJson'
              inputs: {
                content: '@json(triggerBody().data.message)'
                integrationAccount: {
                  map: {
                    name: 'Product2ToProductUpdate'
                  }
                }
              }
            }
          }
          runAfter: {
            Parse_CDC_JSON: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Fix_Transformed_JSON: {
                runAfter: {
                  Transform_JSON_To_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'Compose'
                inputs: '@json(replace(replace(replace(string(body(\'Transform_JSON_To_JSON\')),   \'"now"\',concat(\'"\', utcNow(),\'"\')),\'\t\',\'\'),\'\r\n\',\'\'))'
              }
              Set_CDC_record: {
                runAfter: {
                  Fix_Transformed_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'SetVariable'
                inputs: {
                  name: 'CDCRecord'
                  value: '@outputs(\'Fix_Transformed_JSON\')'
                }
              }
              Transform_JSON_To_JSON: {
                type: 'Liquid'
                kind: 'JsonToJson'
                inputs: {
                  content: '@json(triggerBody().data.message)'
                  integrationAccount: {
                    map: {
                      name: 'Product2ToProduct'
                    }
                  }
                }
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'changeType\']'
                  'UPDATE'
                ]
              }
            ]
          }
          type: 'If'
        }
        Send_CDC_event: {
          runAfter: {
            Condition: [
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
              ContentData: '@base64(variables(\'CDCRecord\'))'
            }
            path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
            queries: {
              partitionKey: '0'
            }
          }
        }
        Parse_Initial_JSON: {
          runAfter: {}
          type: 'ParseJson'
          inputs: {
            content: '@triggerBody()'
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
                          items: {
                            type: 'string'
                          }
                        }
                      }
                    }
                    Name: {}
                    Type: {}
                    RecordTypeId: {}
                    ParentId: {}
                    BillingAddress: {}
                    ShippingAddress: {
                      type: 'object'
                      properties: {
                        Street: {}
                        City: {}
                        State: {}
                        PostalCode: {}
                        Country: {}
                        Latitude: {}
                        Longitude: {}
                        GeocodeAccuracy: {}
                      }
                    }
                    Phone: {}
                    Fax: {}
                    AccountNumber: {}
                    Website: {}
                    Sic: {}
                    Industry: {}
                    AnnualRevenue: {}
                    NumberOfEmployees: {}
                    Ownership: {}
                    TickerSymbol: {}
                    Description: {}
                    Rating: {}
                    Site: {}
                    CurrencyIsoCode: {}
                    OwnerId: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    SourceSystemIdentifier: {}
                    Jigsaw: {}
                    JigsawCompanyId: {}
                    productsource: {}
                    SicDesc: {}
                    OperatingHoursId: {}
                    cgcloud__Account_Email__c: {}
                    cgcloud__Account_Number__c: {}
                    cgcloud__Account_Template__c: {}
                    cgcloud__ExternalId__c: {}
                    cgcloud__Name_2__c: {}
                    cgcloud__Number_Of_Extensions__c: {}
                    SDO_Sales_Closed_Won_Value__c: {}
                  }
                }
              }
            }
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
        }
      }
    }
  }
}

output wf_sf_fabric_omnisync_products_callbackurl string = listCallbackURL('${wf_sf_fabric_omnisync_products.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
