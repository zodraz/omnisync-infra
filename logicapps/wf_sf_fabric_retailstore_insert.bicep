param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_retailstore_insert_name string = 'wf-sf-fabric-omnisync-retailstore-insert-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''
param connections_salesforce_id string=''                
param workflows_wf_sf_d365_omnisyncinc_retailstores_externalid string = ''
 

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
          defaultValue: '005WU00000KkEXaYAN'
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
                            'sf:AccountId__c': {}
                            'sf:Address__City__s': {}
                            'sf:Address__CountryCode__s': {}
                            'sf:Address__GeocodeAccuracy__s': {}
                            'sf:Address__Latitude__s': {}
                            'sf:Address__Longitude__s': {}
                            'sf:Address__PostalCode__s': {}
                            'sf:Address__StateCode__s': {}
                            'sf:Address__Street__s': {}
                            'sf:CreatedById': {}
                            'sf:CreatedDate': {}
                            'sf:CurrencyIsoCode': {}
                            'sf:Description__c': {}
                            'sf:EmployeeCount__c': {}
                            'sf:Fax__c': {}
                            'sf:Id': {}
                            'sf:IsDeleted': {}
                            'sf:LastActivityDate': {}
                            'sf:LastModifiedById': {}
                            'sf:LastModifiedDate': {}
                            'sf:LastReferencedDate': {}
                            'sf:LastViewedDate': {}
                            'sf:Name': {}
                            'sf:OwnerId': {}
                            'sf:Phone__c': {}
                            'sf:StoreCode__c': {}
                            'sf:StoreTypeId__c': {}
                            'sf:StoreType__c': {}
                            'sf:SyncStatus__c': {}
                            'sf:SystemModstamp': {}
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
        XML_notifications_Validation: {
          runAfter: {
            Initialize_notification: [
              'Succeeded'
            ]
          }
          type: 'XmlValidation'
          inputs: {
            content: '@variables(\'notifications\')'
            integrationAccount: {
              schema: {
                name: 'OutboundRetailStore'
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
                  Operation: 'Create'
                  Entity: 'Store'
                  Values: '{ "SalesForceId": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Id\']}", "StoreCode": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}",  "CustomerKey": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:AccountId__c\']}",    "StoreTypeID": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreTypeId__c\']}" , "StoreType": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreType__c\']}" , "StoreName": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Name\']}" , "StoreDescription": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Description__c\']}", "StorePhone": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Phone__c\']}", "StoreFax": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Fax__c\']}", "EmployeeCount": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:EmployeeCount__c\']}","AddressLine1": "@{concat(body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__Street__s\'],\'\',\r\nbody(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__City__s\'],\' \', body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__PostalCode__s\'], \' \', body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__StateCode__s\'], \' \',body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__CountryCode__s\'])}"  ,"CreatedDate": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:CreatedDate\']}", "IsDeleted": "False","UpdatedDate": "@{body(\'Parse_XML_notifications_as_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:LastModifiedDate\']}"}'
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
              'wf-sf-d365-omnisyncinc-retailstores-prod-ne-01': {
                type: 'Workflow'
                inputs: {
                  host: {
                    workflow: {
                      id: workflows_wf_sf_d365_omnisyncinc_retailstores_externalid
                    }
                    triggerName: 'When_a_HTTP_request__is_received'
                  }
                  body: '@body(\'Parse_XML_notifications_as_JSON\')'
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
        Initialize_notification: {
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
