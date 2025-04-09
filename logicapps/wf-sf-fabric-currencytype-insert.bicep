param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sffabricomnisynccurrencyinsert_name string = 'wf-sffabricomnisynccurrencyinsert-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''
param connections_salesforce_id string=''

resource wf_sffabricomnisynccurrencyinsert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sffabricomnisynccurrencyinsert_name
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
        Create_CDC_Currency_Record: {
          runAfter: {
            Transform_CurrencyType_JSON_To_Currency_JSON: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: '"Operation": "Create",\n"Entity": "Currency",\n"Values": "@{body(\'Transform_CurrencyType_JSON_To_Currency_JSON\')}",\n"CreatedDate": "@{utcNow()}",\n"UpdatedDate": "@{utcNow()}"'
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
        Transform_CurrencyType_JSON_To_Currency_JSON: {
          runAfter: {}
          type: 'Liquid'
          kind: 'JsonToJson'
          inputs: {
            content: '@triggerBody()'
            integrationAccount: {
              map: {
                name: 'CurrencyTypeToCurrency'
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
