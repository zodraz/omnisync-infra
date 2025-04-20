param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_accounts_name string = 'wf-sf-d365-omnisyncinc-accounts-${suffix}'
param connections_cds_id string=''

resource wf_sf_d365_omnisync_accounts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_accounts_name
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
        Add_a_new__Account_row: {
          runAfter: {
            Parse_CDC_JSON: [
              'Succeeded'
            ]
          }
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            method: 'post'
            body: {
              name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
              accountnumber: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'cgcloud__Account_Number__c\']}'
              address1_city: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'City\']}'
              address1_line1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Street\']}'
              address1_postalcode: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'PostalCode\']}'
              revenue: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AnnualRevenue\']'
              telephone1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Phone\']}'
              numberofemployees: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'NumberOfEmployees\']'
              address1_country: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'State\']}'
              address1_county: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Country\']}'
              address1_fax: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Fax\']}'
              address1_latitude: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Latitude\']'
              address1_longitude: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Longitude\']'
              emailaddress1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'cgcloud__Account_Email__c\']}'
              fax: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Fax\']}'
            }
            headers: {
              prefer: 'return=representation,odata.include-annotations=*'
              organization: 'https://org58211bdf.crm4.dynamics.com'
            }
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}'
          }
        }
        Parse_CDC_JSON: {
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
                    AccountSource: {}
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
          commondataservice: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/commondataservice'
            connectionId: connections_cds_id
            connectionName: 'commondataservice'
          }
        }
      }
    }
  }
}

output wf_sf_d365_omnisync_accounts_callbackurl string = listCallbackURL('${wf_sf_d365_omnisync_accounts.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
