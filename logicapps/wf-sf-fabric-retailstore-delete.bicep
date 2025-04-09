param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sffabricomnisyncretailstoredelete_name string = 'wf-sffabricomnisyncretailstoredelete-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''

resource wf_sffabricomnisyncretailstoredelete 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sffabricomnisyncretailstoredelete_name
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
        Request: {
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
        Initialize_notifications: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'notifications'
                type: 'object'
                value: '@first(xpath(xml(triggerBody()), \'//*[local-name()="notifications"]\'))'
              }
            ]
          }
        }
        XML_notifications_Validation: {
          runAfter: {
            Initialize_notifications: [
              'Succeeded'
            ]
          }
          type: 'XmlValidation'
          inputs: {
            content: '@variables(\'notifications\')'
            integrationAccount: {
              schema: {
                name: 'OutboundRetailStoreDeletedEvent'
              }
            }
          }
        }
        Bad_XML_Request: {
          runAfter: {
            XML_notifications_Validation: [
              'Failed'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 400
            body: 'Request is not a correct XML RetailStore notification. '
          }
        }
        Create_CDC_Store_record: {
          runAfter: {
            Parse_XML_notifications_as_JSON: [
              'Succeeded'
            ]
          }
          type: 'Compose'
          inputs: {
            Operation: 'Delete'
            Entity: 'Store'
            Values: '{ "SalesForceId": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:DeletedId__c\']}", "StoreCode": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}", "CreatedDate": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:CreatedDate\']}","UpdatedDate": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:LastModifiedDate\']}"}'
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
        Parse_XML_notifications_as_JSON: {
          runAfter: {
            XML_notifications_Validation: [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
          inputs: {
            content: '@json(variables(\'notifications\'))'
            schema: {
              type: 'object'
              properties: {
                notifications: {
                  type: 'object'
                  properties: {
                    '@@xmlns': {
                      type: 'string'
                    }
                    OrganizationId: {
                      type: 'string'
                    }
                    ActionId: {
                      type: 'string'
                    }
                    SessionId: {
                      type: 'object'
                      properties: {
                        '@@xsi:nil': {
                          type: 'string'
                        }
                        '@@xmlns:xsi': {
                          type: 'string'
                        }
                      }
                    }
                    EnterpriseUrl: {
                      type: 'string'
                    }
                    PartnerUrl: {
                      type: 'string'
                    }
                    Notification: {
                      type: 'object'
                      properties: {
                        Id: {
                          type: 'string'
                        }
                        sObject: {
                          type: 'object'
                          properties: {
                            '@@xsi:type': {
                              type: 'string'
                            }
                            '@@xmlns:sf': {
                              type: 'string'
                            }
                            '@@xmlns:xsi': {
                              type: 'string'
                            }
                            'sf:Id': {
                              type: 'string'
                            }
                            'sf:CreatedById': {
                              type: 'string'
                            }
                            'sf:CreatedDate': {
                              type: 'string'
                            }
                            'sf:CurrencyIsoCode': {
                              type: 'string'
                            }
                            'sf:DeletedId__c': {
                              type: 'string'
                            }
                            'sf:IsDeleted': {
                              type: 'string'
                            }
                            'sf:LastModifiedById': {
                              type: 'string'
                            }
                            'sf:LastModifiedDate': {
                              type: 'string'
                            }
                            'sf:Name': {
                              type: 'string'
                            }
                            'sf:OwnerId': {
                              type: 'string'
                            }
                            'sf:StoreCode__c': {
                              type: 'string'
                            }
                            'sf:SystemModstamp': {
                              type: 'string'
                            }
                          }
                        }
                      }
                    }
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
        type: 'Object'
        value: {
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
