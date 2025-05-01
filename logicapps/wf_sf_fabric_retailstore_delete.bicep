param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_retailstore_delete_name string = 'wf-sf-fabric-omnisync-retailstore-delete-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''

resource wf_sf_fabric_omnisync_retailstore_delete 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_retailstore_delete_name
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
        Request: {
          type: 'Request'
          kind: 'Http'
        }
      }
      actions: {
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
        Check_Integration_user: {
          actions: {}
          runAfter: {
            Parse_XML_notifications_as_JSON: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Create_CDC_Store_record: {
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
                      name: '@parameters(\'$connections\')[\'eventhubs-1\'][\'connectionId\']'
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
                  '@body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:CreatedById\']'
                  '@parameters(\'integration_user\')'
                ]
              }
              {
                equals: [
                  '@body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:LastModifiedById\']'
                  '@parameters(\'integration_user\')'
                ]
              }
            ]
          }
          type: 'If'
        }
        Response_notification_ack: {
          runAfter: {
            Check_Integration_user: [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
            body: '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">\n\n    <soap:Body>\n\n        <notificationsResponse xmlns:ns2="urn:sobject.enterprise.soap.sforce.com" xmlns="http://soap.sforce.com/2005/09/outbound">\n\n            <Ack>true</Ack>\n\n        </notificationsResponse>\n\n    </soap:Body>\n\n</soap:Envelope>'
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
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/eventhubs'
            connectionId: connections_eventhubs_id
            connectionName: 'eventhubs'
          }
        }
      }
    }
  }
}
