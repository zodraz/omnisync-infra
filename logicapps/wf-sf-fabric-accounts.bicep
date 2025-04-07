param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sffabricomnisyncaccounts_name string = 'wf-sffabricomnisyncincaccounts-${suffix}'
param ia_omnisync_id string=''
param con_eh_id string=''

resource wf_sffabricomnisyncaccounts 'Microsoft.Logic/workflows@2017-07-01' = {
  name: wf_sffabricomnisyncaccounts_name
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
          runAfter: {}
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
                        Street: {
                          type: 'string'
                        }
                        City: {
                          type: 'string'
                        }
                        State: {
                          type: 'string'
                        }
                        PostalCode: {
                          type: 'string'
                        }
                        Country: {
                          type: 'string'
                        }
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
                    LastModifiedDate: {
                      type: 'integer'
                    }
                    LastModifiedById: {}
                    SourceSystemIdentifier: {}
                    Jigsaw: {}
                    JigsawCompanyId: {}
                    AccountSource: {}
                    SicDesc: {}
                    OperatingHoursId: {}
                    cgcloud__Account_Email__c: {
                      type: 'string'
                    }
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
            Transform_JSON_To_JSON_Update: {
              type: 'Liquid'
              kind: 'JsonToJson'
              inputs: {
                content: '@body(\'Parse_CDC_JSON\').data.message'
                integrationAccount: {
                  map: {
                    name: 'AccountToCustomerUpdate'
                  }
                }
              }
            }
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
          }
          runAfter: {
            Parse_CDC_JSON: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Transform_JSON_To_JSON: {
                type: 'Liquid'
                kind: 'JsonToJson'
                inputs: {
                  content: '@triggerBody().data.message'
                  integrationAccount: {
                    map: {
                      name: 'AccountToCustomer'
                    }
                  }
                }
              }
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
            path: '/@{encodeURIComponent(\'eh-omnisync-${suffix}\')}/events'
            queries: {
              partitionKey: '0'
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
            connectionId: con_eh_id
            connectionName: 'eventhubs'
          }
        }
      }
    }
  }
}

output wf_sffabricomnisyncaccounts_callbackurl string = listCallbackURL('${wf_sffabricomnisyncaccounts.id}/triggers/When_a_HTTP_request_is_received', '2017-07-01').value
