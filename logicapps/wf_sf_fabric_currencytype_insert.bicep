param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_currency_insert_name string = 'wf-sf-fabric-omnisync-currency-insert-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''
param connections_salesforce_id string=''

resource wf_sf_fabric_omnisync_currency_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_currency_insert_name
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
        integration_user: {
          defaultValue: 'integration1@omnisync.com'
          type: 'String'
        }
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_CurrencyType_record_is_created: {
          recurrence: {
            interval: 1
            frequency: 'Minute'
          }
          evaluatedRecurrence: {
            interval: 1
            frequency: 'Minute'
          }
          splitOn: '@triggerBody()?[\'value\']'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'CurrencyType\'))}/onnewitems'
          }
        }
      }
      actions: {
        Condition: {
          actions: {}
          runAfter: {}
          else: {
            actions: {
              Transform_CurrencyType_JSON_To_Currency_JSON: {
                type: 'Liquid'
                kind: 'JsonToJson'
                inputs: {
                  content: '@triggerBody()'
                  integrationAccount: {
                    map: {
                      name: 'SalesForceCurrencyTypeToCurrency'
                    }
                  }
                }
              }
              Fix_Transformated_JSON: {
                runAfter: {
                  Transform_CurrencyType_JSON_To_Currency_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'Compose'
                inputs: '@json(replace(replace(replace(string(body(\'Transform_CurrencyType_JSON_To_Currency_JSON\')),   \'"now"\',concat(\'"\', utcNow(),\'"\')),\'\t\',\'\'),\'\r\n\',\'\'))'
              }
              Create_CDC_Currency_Record: {
                runAfter: {
                  Fix_Transformated_JSON: [
                    'Succeeded'
                  ]
                }
                type: 'Compose'
                inputs: '@outputs(\'Fix_Transformated_JSON\')'
              }
              Send_CDC_event: {
                runAfter: {
                  Create_CDC_Currency_Record: [
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
                    ContentData: '@base64(outputs(\'Create_CDC_Currency_Record\'))'
                  }
                  path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
                  queries: {
                    partitionKey: '0'
                  }
                }
              }
            }
          }
          expression: {
            or: [
              {
                equals: [
                  '@triggerBody()?[\'CreatedById\']'
                  '@parameters(\'integration_user\')'
                ]
              }
              {
                equals: [
                  '@triggerBody()?[\'LastModifiedById\']'
                  '@parameters(\'integration_user\')'
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
