param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_retailstores_update_name string = 'wf-d365-omnisyncinc-retailstores-update-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_d365_omnisync_retailstores_update 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_retailstores_update_name
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
              entityname: 'cr989_retailstore'
              message: 3
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
                          name: 'D365RetailStoreToStore'
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
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Store\' AND SalesForceId IS NOT NULL'
                    formalParameters: {
                      D365Id: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      D365Id: '@triggerBody()?[\'cr989_retailstoreid\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              'Check_if_Mapping_RetailStore_(for_Update)_row_exists_': {
                actions: {
                  Get_Account: {
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
                        organization: 'https://org58211bdf.crm4.dynamics.com'
                      }
                      path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'_cr989_account_value\']))})'
                    }
                  }
                  Get_SalesForce_Account: {
                    runAfter: {
                      Get_Account: [
                        'Succeeded'
                      ]
                    }
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'get'
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items'
                      queries: {
                        '$filter': 'Name eq \'@{body(\'Get_Account\')?[\'name\']}\''
                      }
                    }
                  }
                  Update_RetailStore: {
                    runAfter: {
                      Get_SalesForce_Account: [
                        'Succeeded'
                      ]
                    }
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'patch'
                      body: {
                        AccountId__c: '@first(body(\'Get_SalesForce_Account\')?[\'value\'])?[\'Id\']'
                        StoreType__c: '@{triggerBody()?[\'_cr989_storetype_label\']}'
                        StoreCode__c: '@triggerBody()?[\'cr989_storecode\']'
                        Name: '@triggerBody()?[\'cr989_storename\']'
                        CurrencyIsoCode: 'EUR'
                        Description__c: '@triggerBody()?[\'cr989_storedescription\']'
                        EmployeeCount__c: '@triggerBody()?[\'cr989_employeecount\']'
                        Fax__c: '@triggerBody()?[\'cr989_storefax\']'
                        Phone__c: '@triggerBody()?[\'cr989_storephone\']'
                        StoreTypeId__c: '@triggerBody()?[\'cr989_storetype\']'
                      }
                      path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'RetailStore__c\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_SalesForceId_for_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'SalesForceId\']))}'
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
                    'Response_RetailStore_not_found_(on_Update)': {
                      type: 'Response'
                      kind: 'Http'
                      inputs: {
                        statusCode: 404
                        body: 'RetailStore @{triggerBody()?[\'cr989_storecode\']}-@{triggerBody()?[\'cr989_storename\']}  to update not found on Dynamics365'
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
