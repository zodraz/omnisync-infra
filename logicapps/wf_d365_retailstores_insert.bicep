param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_retailstores_insert_name string = 'wf-d365-omnisyncinc-retailstores-insert-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''


resource wf_d365_omnisync_retailstores_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_retailstores_insert_name
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
              Get_Mapped_SalesForceId: {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                    }
                  }
                  method: 'post'
                  body: {
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Store\' AND SalesForceId IS NULL'
                    formalParameters: {
                      Name: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      Name: '@triggerBody()?[\'cr989_storename\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              Check_if_Store_exists_in_SalesForce: {
                actions: {
                  Delay_for_CDC_on_SalesForce_on_Fabric: {
                    runAfter: {
                      Create_RetailStore: [
                        'Succeeded'
                      ]
                    }
                    type: 'Wait'
                    inputs: {
                      interval: {
                        count: 0
                        unit: 'Second'
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
                        query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'RetailStore\' AND D365Id IS NOT NULL'
                        formalParameters: {
                          Name: 'NVARCHAR(100)'
                        }
                        actualParameters: {
                          Name: '@triggerBody()?[\'cr989_storename\']'
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
                      Values: '{ "SalesForceIdToInsert": "@{body(\'Create_RetailStore\')[\'Id\']}","D365Id": "@{triggerBody()?[\'cr989_retailstoreid\']}"}'
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
                  Create_RetailStore: {
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
                      method: 'post'
                      body: {
                        AccountId__c: '@first(body(\'Get_SalesForce_Account\')?[\'value\'])?[\'Id\']'
                        StoreType__c: '@triggerBody()?[\'_cr989_storetype_label\']'
                        StoreCode__c: '@triggerBody()?[\'cr989_storecode\']'
                        Name: '@triggerBody()?[\'cr989_storename\']'
                        CurrencyIsoCode: 'EUR'
                        Description__c: '@triggerBody()?[\'cr989_storedescription\']'
                        EmployeeCount__c: '@triggerBody()?[\'cr989_employeecount\']'
                        Fax__c: '@triggerBody()?[\'cr989_storefax\']'
                        Phone__c: '@triggerBody()?[\'cr989_storephone\']'
                        StoreTypeId__c: '@triggerBody()?[\'cr989_storetype\']'
                      }
                      path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'RetailStore__c\'))}/items'
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
                    Update_Status_RetailStore: {
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
                          organization: 'https://org58211bdf.crm4.dynamics.com'
                        }
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'cr989_retailstores\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'cr989_retailstoreid\']))})'
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
