param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_accounts_insert_name string = 'wf-d365-omnisyncinc-accounts-insert-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''
param d365_organization string=''
param integration_user string=''
param database string =''
param sql_connection_string string = ''

resource wf_d365_omnisync_accounts_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_accounts_insert_name
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
          defaultValue: 'b4c42b2a-181e-f011-9989-002248a3370c'
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
              message: 1
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
        Check_Integration_user: {
          actions: {}
          runAfter: {
            Get_Integration_user: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
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
              Get_Mapped_SalesForceId: {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'sql-1\'][\'connectionId\']'
                    }
                  }
                  method: 'post'
                  body: {
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\' AND SalesForceId IS NULL'
                    formalParameters: {
                      Name: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      Name: '@triggerBody()?[\'accountnumber\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              Check_if_AccountNumber_exists_in_SalesForce: {
                actions: {
                  Create_Account: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce-1\'][\'connectionId\']'
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
                        CurrencyIsoCode: 'EUR'
                        Email__c: '@triggerBody()?[\'emailaddress1\']'
                      }
                      path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items'
                    }
                  }
                  Delay_for_CDC_on_SalesForce_on_Fabric: {
                    runAfter: {
                      Create_Account: [
                        'Succeeded'
                      ]
                    }
                    type: 'Wait'
                    inputs: {
                      interval: {
                        count: 3
                        unit: 'Minute'
                      }
                    }
                  }
                  Get_Mapped_D365Id_for_Insert_to_Update: {
                    runAfter: {
                      Delay_for_CDC_on_SalesForce_on_Fabric: [
                        'Succeeded'
                      ]
                    }
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                        }
                      }
                      method: 'post'
                      body: {
                        query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\' AND D365Id IS NOT NULL'
                        formalParameters: {
                          Name: 'NVARCHAR(100)'
                        }
                        actualParameters: {
                          Name: '@triggerBody()?[\'accountnumber\']'
                        }
                      }
                      path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                    }
                  }
                  Create_CDC_Store: {
                    runAfter: {
                      Get_Mapped_D365Id_for_Insert_to_Update: [
                        'Succeeded'
                      ]
                    }
                    type: 'Compose'
                    inputs: {
                      Operation: 'Update'
                      Entity: 'MasterDataMapping'
                      Values: '{ "SalesForceIdToInsert": "@{body(\'Create_Account\')[\'Id\']}","D365Id": "@{triggerBody()?[\'accountid\']}"}'
                      CreatedDate: '@utcNow()'
                      UpdatedDate: '@utcNow()'
                    }
                  }
                  Send_CDC_event_for_SalesForce_insert: {
                    runAfter: {
                      Create_CDC_Store: [
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
                        ContentData: '@base64(outputs(\'Create_CDC_Store\'))'
                      }
                      path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
                      queries: {
                        partitionKey: '0'
                      }
                    }
                  }
                }
                runAfter: {
                  Get_Mapped_SalesForceId: [
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
                            name: '@parameters(\'$connections\')[\'commondataservice-1\'][\'connectionId\']'
                          }
                        }
                        method: 'patch'
                        body: {
                          omnisync_syncstatus: 'Conflict'
                        }
                        headers: {
                          prefer: 'return=representation,odata.include-annotations=*'
                          accept: 'application/json;odata.metadata=full'
                          organization: 'https://org58211bdf.crm4.dynamics.com'
                        }
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'accountnumber\']))})'
                      }
                    }
                  }
                }
                expression: {
                  and: [
                    {
                      equals: [
                        '@length(string(body(\'Get_Mapped_SalesForceId\')?[\'resultsets\']))'
                        2
                      ]
                    }
                  ]
                }
                type: 'If'
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
                    name: '@parameters(\'$connections\')[\'commondataservice-1\'][\'connectionId\']'
                  }
                }
                method: 'get'
                headers: {
                  prefer: 'odata.include-annotations=*'
                  accept: 'application/json;odata.metadata=full'
                  organization: 'https://org58211bdf.crm4.dynamics.com'
                }
                path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'audits\'))}'
                queries: {
                  '$filter': '_objectid_value eq  \'@{triggerBody()?[\'ItemInternalId\']}\''
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
                  userId: '@first(outputs(\'Get_audit_rows\')?[\'body/value\'])?[\'_userid_value\']'
                }
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
