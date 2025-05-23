param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_retailstore_insert_name string = 'wf-sf-fabric-omnisync-retailstore-insert-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''
param connections_salesforce_id string=''

resource wf_sf_fabric_omnisync_retailstore_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_retailstore_insert_name
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
        When_a_RetailStore_record_is_inserted: {
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
            path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'RetailStore\'))}/onnewitems'
          }
        }
      }
      actions: {
        Check_Integration_user: {
          actions: {}
          runAfter: {}
          else: {
            actions: {
              Create_CDC_Store_record: {
                type: 'Compose'
                inputs: {
                  Operation: 'Create'
                  Entity: 'Store'
                  Values: '{ "SalesForceId": "@{triggerBody()?[\'Id\']}","CustomerKey": "@{triggerBody()?[\'AccountId\']}", "StoreTypeID":@{triggerBody()?[\'StoreTypeID__c\']} , "StoreType": "@{triggerBody()?[\'StoreType\']}", "StoreCode": "@{triggerBody()?[\'StoreCode__c\']}", "StoreName": "@{triggerBody()?[\'Name\']}","StoreDescription": "@{triggerBody()?[\'Description\']}","AddressLine1": "@{concat(triggerBody()?[\'Street\'],\' \', triggerBody()?[\'City\'],\' \',triggerBody()?[\'PostalCode\'],\' \',triggerBody()?[\'State\'],\' \',triggerBody()?[\'Country\'])}", "StorePhone": "@{triggerBody()?[\'Phone__c\']}",  "StoreFax": "@{triggerBody()?[\'Fax__c\']}", "EmployeeCount": "@{triggerBody()?[\'EmployeeCount__c\']}","Latitude": "@{triggerBody()?[\'Latitude\']}","Longitude": "@{triggerBody()?[\'Longitude\']}","IsDeleted": "False","CreatedDate": "@{triggerBody()?[\'CreatedDate\']}","UpdatedDate": "@{triggerBody()?[\'LastModifiedDate\']}"}'
                  CreatedDate: '@utcNow()'
                  UpdatedDate: '@utcNow()'
                }
              }
              Send_CDC_event: {
                runAfter: {
                  Create_CDC_Store_record: [
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
                    ContentData: '@base64(outputs(\'Create_CDC_Store_record\'))'
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
        type: 'Object'
        value: {
          salesforce: {
            id: '/subscriptions/1145166d-1e2c-41f1-a2ca-4325731080ed/providers/Microsoft.Web/locations/northeurope/managedApis/salesforce'
            connectionId: connections_salesforce_id
            connectionName: 'salesforce'
          }
          eventhubs: {
            id: '/subscriptions/1145166d-1e2c-41f1-a2ca-4325731080ed/providers/Microsoft.Web/locations/northeurope/managedApis/eventhubs'
            connectionId: connections_eventhubs_id
            connectionName: 'eventhubs'
          }
        }
      }
    }
  }
}
