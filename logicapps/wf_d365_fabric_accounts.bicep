param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_fabric_omnisync_accounts_name string = 'wf-sf-fabric-omnisyncinc-accounts-${suffix}'
param ia_omnisync_id string=''
param connections_eventhubs_id string=''
param connections_cds_id string=''

resource wf_sf_fabric_omnisync_accounts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_fabric_omnisync_accounts_name
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
          defaultValue: ' integration@OmniSyncv1.onmicrosoft.com'
          type: 'String'
        }
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_a_row_is_added,_modified_or_deleted': {
          type: 'ApiConnectionWebhook'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
              }
            }
            body: {
              entityname: 'account'
              message: 7
              scope: 4
              version: 1
              url: '@listCallbackUrl()'
            }
            headers: {
              organization: 'https://org58211bdf.crm4.dynamics.com'
              Consistency: 'Strong'
              catalog: 'all'
              category: 'all'
            }
            path: '/api/data/v9.1/callbackregistrations'
          }
        }
      }
      actions: {
        Check_Integration_User: {
          actions: {}
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
                  content: '@triggerBody()'
                  integrationAccount: {
                    map: {
                      name: 'D365AccountToCustomer'
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
              Create_CDC_Record: {
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
              Send_CDC_event: {
                runAfter: {
                  Create_CDC_Record: [
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
            }
          }
          expression: {
            or: [
              {
                equals: [
                  '@triggerBody()?[\'_createdby_value\']'
                  '@parameters(\'integration_user\')'
                ]
              }
              {
                equals: [
                  '@triggerBody()?[\'_modifiedby_value\']'
                  ''
                ]
              }
            ]
          }
          type: 'If'
        }
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
            content: '@triggerBody()'
            schema: {
              type: 'object'
              properties: {
                address2_addresstypecode: {
                  type: 'integer'
                }
                _address2_addresstypecode_label: {
                  type: 'string'
                }
                merged: {
                  type: 'boolean'
                }
                statecode: {
                  type: 'integer'
                }
                _statecode_label: {
                  type: 'string'
                }
                exchangerate: {
                  type: 'integer'
                }
                address1_composite: {
                  type: 'string'
                }
                tickersymbol: {
                  type: 'string'
                }
                ownershipcode: {
                  type: 'integer'
                }
                _ownershipcode_label: {
                  type: 'string'
                }
                websiteurl: {
                  type: 'string'
                }
                opendeals: {
                  type: 'integer'
                }
                modifiedon: {
                  type: 'string'
                }
                _primarycontactid_value: {
                  type: 'string'
                }
                '_primarycontactid_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _primarycontactid_type: {
                  type: 'string'
                }
                openrevenue_state: {
                  type: 'integer'
                }
                donotpostalmail: {
                  type: 'boolean'
                }
                accountratingcode: {
                  type: 'integer'
                }
                _accountratingcode_label: {
                  type: 'string'
                }
                numberofemployees: {
                  type: 'integer'
                }
                marketingonly: {
                  type: 'boolean'
                }
                revenue_base: {
                  type: 'integer'
                }
                preferredcontactmethodcode: {
                  type: 'integer'
                }
                _preferredcontactmethodcode_label: {
                  type: 'string'
                }
                _ownerid_value: {
                  type: 'string'
                }
                '_ownerid_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _ownerid_type: {
                  type: 'string'
                }
                description: {
                  type: 'string'
                }
                sic: {
                  type: 'string'
                }
                customersizecode: {
                  type: 'integer'
                }
                _customersizecode_label: {
                  type: 'string'
                }
                name: {
                  type: 'string'
                }
                openrevenue_date: {
                  type: 'string'
                }
                openrevenue_base: {
                  type: 'integer'
                }
                businesstypecode: {
                  type: 'integer'
                }
                _businesstypecode_label: {
                  type: 'string'
                }
                donotemail: {
                  type: 'boolean'
                }
                opendeals_state: {
                  type: 'integer'
                }
                msdyn_gdproptout: {
                  type: 'boolean'
                }
                followemail: {
                  type: 'boolean'
                }
                createdon: {
                  type: 'string'
                }
                creditlimit: {
                  type: 'integer'
                }
                address1_stateorprovince: {
                  type: 'string'
                }
                openrevenue: {
                  type: 'integer'
                }
                donotsendmm: {
                  type: 'boolean'
                }
                donotfax: {
                  type: 'boolean'
                }
                donotbulkpostalmail: {
                  type: 'boolean'
                }
                address1_country: {
                  type: 'string'
                }
                address1_line1: {
                  type: 'string'
                }
                creditonhold: {
                  type: 'boolean'
                }
                telephone1: {
                  type: 'string'
                }
                donotphone: {
                  type: 'boolean'
                }
                _transactioncurrencyid_value: {
                  type: 'string'
                }
                '_transactioncurrencyid_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _transactioncurrencyid_type: {
                  type: 'string'
                }
                accountid: {
                  type: 'string'
                }
                donotbulkemail: {
                  type: 'boolean'
                }
                creditlimit_base: {
                  type: 'integer'
                }
                _modifiedby_value: {
                  type: 'string'
                }
                '_modifiedby_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _modifiedby_type: {
                  type: 'string'
                }
                cr989_syncorigin: {
                  type: 'string'
                }
                shippingmethodcode: {
                  type: 'integer'
                }
                _shippingmethodcode_label: {
                  type: 'string'
                }
                _createdby_value: {
                  type: 'string'
                }
                '_createdby_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _createdby_type: {
                  type: 'string'
                }
                address1_city: {
                  type: 'string'
                }
                territorycode: {
                  type: 'integer'
                }
                _territorycode_label: {
                  type: 'string'
                }
                statuscode: {
                  type: 'integer'
                }
                _statuscode_label: {
                  type: 'string'
                }
                fax: {
                  type: 'string'
                }
                revenue: {
                  type: 'integer'
                }
                participatesinworkflow: {
                  type: 'boolean'
                }
                accountclassificationcode: {
                  type: 'integer'
                }
                _accountclassificationcode_label: {
                  type: 'string'
                }
                _owningbusinessunit_value: {
                  type: 'string'
                }
                '_owningbusinessunit_value@Microsoft.Dynamics.CRM.lookuplogicalname': {
                  type: 'string'
                }
                _owningbusinessunit_type: {
                  type: 'string'
                }
                address1_postalcode: {
                  type: 'string'
                }
                opendeals_date: {
                  type: 'string'
                }
                ItemInternalId: {
                  type: 'string'
                }
                SdkMessage: {
                  type: 'string'
                }
                RunAsSystemUserId: {
                  type: 'string'
                }
                RowVersion: {
                  type: 'string'
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
