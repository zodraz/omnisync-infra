param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_accounts_name string = 'wf-d365-omnisyncinc-accounts-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''
param d365_organization string=''
param integration_user string=''
param database string =''
param sql_connection_string string = ''

resource wf_d365_omnisync_accounts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_accounts_name
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
          defaultValue: integration_user
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
              organization: 'https://${d365_organization}.crm4.dynamics.com'
              Consistency: 'Strong'
              catalog: 'all'
              category: 'all'
            }
            path: '/api/data/v9.1/callbackregistrations'
          }
        }
      }
      actions: {
        Check_Integration_user: {
          actions: {}
          runAfter: {
            Get_Integration_user: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Operation: {
                cases: {
                  Create: {
                    case: 'Create'
                    actions: {
                      Check_if_AccountNumber_exists_in_SalesForce: {
                        actions: {
                          Create_Account: {
                            type: 'ApiConnection'
                            inputs: {
                              host: {
                                connection: {
                                  name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                                }
                              }
                              method: 'post'
                              body: {
                                Name: '@triggerBody()?[\'name\']'
                                BillingStreet: '@triggerBody()?[\'address1_line1\']'
                                BillingCity: '@triggerBody()?[\'address1_city\']'
                                BillingState: '@triggerBody()?[\'address1_stateorprovince\']'
                                BillingPostalCode: '@triggerBody()?[\'address1_postalcode\']'
                                BillingCountry: '@triggerBody()?[\'address1_country\']'
                                AccountNumber: '@triggerBody()?[\'accountnumber\']'
                                Type: 'Customer'
                                BillingLatitude: '@triggerBody()?[\'address1_latitude\']'
                                BillingLongitude: '@triggerBody()?[\'address1_longitude\']'
                                Phone: '@triggerBody()?[\'telephone1\']'
                                Fax: '@triggerBody()?[\'fax\']'
                                Website: '@triggerBody()?[\'websiteurl\']'
                                Industry: 'Retail'
                                AnnualRevenue: '@triggerBody()?[\'revenue\']'
                                NumberOfEmployees: '@triggerBody()?[\'numberofemployees\']'
                                CurrencyIsoCode: '@triggerBody()?[\'_transactioncurrencyid_value@Microsoft.Dynamics.CRM.lookuplogicalname\']'
                                cgcloud__Account_Email__c: '@triggerBody()?[\'emailaddress1\']'
                                cgcloud__Account_Number__c: '@triggerBody()?[\'accountnumber\']'
                              }
                              path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items'
                            }
                          }
                        }
                        runAfter: {
                          Get_Mapped_SalesForceId_for_Insert: [
                            'Succeeded'
                          ]
                        }
                        else: {
                          actions: {
                            Update_Status_Account: {
                              type: 'ApiConnection'
                              inputs: {
                                host: {
                                  connection: {
                                    name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                                  }
                                }
                                method: 'patch'
                                body: {
                                  omnisync_syncstatus: 'Conflict'
                                }
                                headers: {
                                  prefer: 'return=representation,odata.include-annotations=*'
                                  accept: 'application/json;odata.metadata=full'
                                  organization: 'https://${d365_organization}.crm4.dynamics.com'
                                }
                                path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'accountid\']))})'
                              }
                            }
                          }
                        }
                        expression: {
                          and: [
                            {
                              equals: [
                                '@length(string(body(\'Get_Mapped_SalesForceId_for_Insert\')?[\'resultsets\']))'
                                2
                              ]
                            }
                          ]
                        }
                        type: 'If'
                      }
                      Get_Mapped_SalesForceId_for_Insert: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            query: 'SELECT * \nFROM ${database}.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\''
                            formalParameters: {
                              Name: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              Name: '@triggerBody()?[\'accountnumber\']'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${sql_connection_string}\'))},@{encodeURIComponent(encodeURIComponent(\'${database}\'))}/query/sql'
                        }
                      }
                    }
                  }
                  Update: {
                    case: 'Update'
                    actions: {
                      Get_Mapped_SalesForceId_for_Update: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            query: 'SELECT * \nFROM ${database}.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Customer\''
                            formalParameters: {
                              D365Id: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              D365Id: '@triggerBody()?[\'accountid\']'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${sql_connection_string}\'))},@{encodeURIComponent(encodeURIComponent(\'${database}\'))}/query/sql'
                        }
                      }
                      'Check_if_Mapping_Customer_(for_Update)_row_exists_': {
                        actions: {
                          Update_Account: {
                            type: 'ApiConnection'
                            inputs: {
                              host: {
                                connection: {
                                  name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                                }
                              }
                              method: 'patch'
                              body: {
                                Name: '@triggerBody()?[\'name\']'
                                BillingStreet: '@triggerBody()?[\'address1_line1\']'
                                BillingCity: '@triggerBody()?[\'address1_city\']'
                                BillingState: '@triggerBody()?[\'address1_stateorprovince\']'
                                BillingPostalCode: '@triggerBody()?[\'address1_postalcode\']'
                                BillingCountry: '@triggerBody()?[\'address2_country\']'
                                AccountNumber: '@triggerBody()?[\'accountnumber\']'
                                BillingLatitude: '@triggerBody()?[\'address1_latitude\']'
                                BillingLongitude: '@triggerBody()?[\'address1_longitude\']'
                                Phone: '@triggerBody()?[\'telephone1\']'
                                Fax: '@triggerBody()?[\'address1_fax\']'
                                Website: '@triggerBody()?[\'websiteurl\']'
                                Industry: 'Retail'
                                AnnualRevenue: '@triggerBody()?[\'revenue\']'
                                NumberOfEmployees: '@triggerBody()?[\'numberofemployees\']'
                                Description: '@triggerBody()?[\'description\']'
                                CurrencyIsoCode: '@triggerBody()?[\'_transactioncurrencyid_value@Microsoft.Dynamics.CRM.lookuplogicalname\']'
                                cgcloud__Account_Email__c: '@triggerBody()?[\'emailaddress1\']'
                                cgcloud__Account_Number__c: '@triggerBody()?[\'accountnumber\']'
                              }
                              path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Mapped_SalesForceId_for_Update\'))?[\'SalesForceId\']))}'
                            }
                          }
                        }
                        runAfter: {
                          Get_Mapped_SalesForceId_for_Update: [
                            'Succeeded'
                          ]
                        }
                        else: {
                          actions: {
                            'Response_Account_not_found_(on_Update)': {
                              type: 'Response'
                              kind: 'Http'
                              inputs: {
                                statusCode: 404
                                body: 'Account  @{triggerBody()?[\'accountnumber\']}- @{triggerBody()?[\'name\']} to update not found on Dynamics365'
                              }
                            }
                          }
                        }
                        expression: {
                          and: [
                            {
                              not: {
                                equals: [
                                  '@length(string(body(\'Get_Mapped_SalesForceId_for_Update\')?[\'resultsets\']))'
                                  2
                                ]
                              }
                            }
                          ]
                        }
                        type: 'If'
                      }
                    }
                  }
                  Delete: {
                    case: 'Delete'
                    actions: {
                      Get_Mapped_SalesForceId_for_Delete: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            query: 'SELECT * \nFROM ${database}.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Customer\''
                            formalParameters: {
                              D365Id: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              D365Id: '@triggerBody()?[\'accountid\']'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'${sql_connection_string}\'))},@{encodeURIComponent(encodeURIComponent(\'${database}\'))}/query/sql'
                        }
                      }
                      'Check_if_Mapping_Customer_(for_Delete)_row_exists_': {
                        actions: {
                          Delete_Account: {
                            type: 'ApiConnection'
                            inputs: {
                              host: {
                                connection: {
                                  name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                                }
                              }
                              method: 'delete'
                              path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Mapped_SalesForceId_for_Delete\'))?[\'SalesForceId\']))}'
                            }
                          }
                        }
                        runAfter: {
                          Get_Mapped_SalesForceId_for_Delete: [
                            'Succeeded'
                          ]
                        }
                        else: {
                          actions: {
                            'Response_Account_not_found_(on_Delete)': {
                              type: 'Response'
                              kind: 'Http'
                              inputs: {
                                statusCode: 404
                                body: 'Account with D365Id  @{triggerBody()?[\'accountid\']} to delete not found on Dynamics365'
                              }
                            }
                          }
                        }
                        expression: {
                          and: [
                            {
                              not: {
                                equals: [
                                  '@length(string(body(\'Get_Mapped_SalesForceId_for_Delete\')?[\'resultsets\']))'
                                  2
                                ]
                              }
                            }
                          ]
                        }
                        type: 'If'
                      }
                    }
                  }
                }
                default: {
                  actions: {
                    Response_Not_Supported: {
                      type: 'Response'
                      kind: 'Http'
                      inputs: {
                        statusCode: 400
                        body: 'Operation not supported'
                      }
                    }
                  }
                }
                expression: '@triggerBody()?[\'SdkMessage\']'
                type: 'Switch'
              }
              Send_to_Fabric: {
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
                type: 'Scope'
              }
            }
          }
          expression: {
            and: [
              {
                greater: [
                  '@length(body(\'Filter_Integration_Users\'))'
                  0
                ]
              }
            ]
          }
          type: 'If'
        }
        Get_Integration_user: {
          actions: {
            Get_audit_rows: {
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                  }
                }
                method: 'get'
                headers: {
                  prefer: 'odata.include-annotations=*'
                  accept: 'application/json;odata.metadata=full'
                  organization: 'https://${d365_organization}.crm4.dynamics.com'
                }
                path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'audits\'))}'
                queries: {
                  '$filter': '_objectid_value eq  \'@{triggerBody()?[\'ItemInternalId\']}\''
                }
              }
            }
            Select_Users: {
              runAfter: {
                Get_audit_rows: [
                  'Succeeded'
                ]
              }
              type: 'Select'
              inputs: {
                from: '@outputs(\'Get_audit_rows\')?[\'body/value\']'
                select: {
                  userId: '_userid_value'
                }
              }
            }
            Filter_Integration_Users: {
              runAfter: {
                Select_Users: [
                  'Succeeded'
                ]
              }
              type: 'Query'
              inputs: {
                from: '@body(\'Select_users\')'
                where: '@equals(item()?[\'userId\'],parameters(\'integration_user\'))'
              }
            }
          }
          runAfter: {
            Initialize_CDC_record: [
              'Succeeded'
            ]
          }
          type: 'Scope'
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
          salesforce: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/salesforce'
            connectionId: connections_salesforce_id
            connectionName: 'salesforce'
          }
          sql: {
            id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
            connectionId: connections_sql_id
            connectionName: 'sql'
          }
        }
      }
    }
  }
}
