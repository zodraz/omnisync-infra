param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_orders_insert_name string = 'wf-d365-omnisyncinc-orders-insert-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''
param d365_organization string=''
param integration_user string=''
param database string =''
param sql_connection_string string = ''

resource wf_d365_omnisync_orders_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_orders_insert_name
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
              entityname: 'salesorder'
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
              Check_if_AccountNumber_exists_in_SalesForce: {
                actions: {
                  Create_Order: {
                    runAfter: {
                      Get_Mapped_SalesForceId_for_Account: [
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
                        EffectiveDate: '@triggerBody()?[\'requestdeliveryby\']'
                        Status: 'Draft'
                        RetailStore__c: '@body(\'Get_Mapped_SalesForceId_for_RetailStore\')?[\'resultsets\']?[\'Table1\']?[0]?[\'SalesForceId\']'
                        ContractId: '800WU00000n5SSVYA2'
                        AccountId: '@body(\'Get_Mapped_SalesForceId_for_Account\')?[\'resultsets\']?[\'Table1\']?[0]?[\'SalesForceId\']'
                        Pricebook2Id: '@first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_sfstandardpricebook\']'
                        Description: '@triggerBody()?[\'description\']'
                        Name: '@triggerBody()?[\'name\']'
                        OrderReferenceNumber: '@triggerBody()?[\'ordernumber\']'
                        CurrencyIsoCode: 'EUR'
                        D365OrderNumber__c: '@triggerBody()?[\'ordernumber\']'
                      }
                      path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items'
                    }
                  }
                  Create_CDC_Store: {
                    runAfter: {
                      Create_Order: [
                        'Succeeded'
                      ]
                    }
                    type: 'Compose'
                    inputs: {
                      Operation: 'Create'
                      Entity: 'MasterDataMapping'
                      Values: '{ "SalesForceId": "@{body(\'Create_Order\')?[\'Id\']}","D365Id": "@{triggerBody()?[\'salesorderid\']}","Entity":"Order","Name":"@{triggerBody()?[\'ordernumber\']}","CreatedDate":"@{utcNow()}","UpdatedDate":"@{utcNow()}"}'
                      CreatedDate: '@utcNow()'
                      UpdatedDate: '@utcNow()'
                    }
                  }
                  Send_CDC_event: {
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
                  Get_Mapped_SalesForceId_for_RetailStore: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                        }
                      }
                      method: 'post'
                      body: {
                        query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Store\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                        formalParameters: {
                          D365Id: 'NVARCHAR(100)'
                        }
                        actualParameters: {
                          D365Id: '@triggerBody()?[\'_cr989_retailstore_value\']'
                        }
                      }
                      path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                    }
                  }
                  Get_Mapped_SalesForceId_for_Account: {
                    runAfter: {
                      Get_Mapped_SalesForceId_for_RetailStore: [
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
                        query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Customer\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                        formalParameters: {
                          D365Id: 'NVARCHAR(100)'
                        }
                        actualParameters: {
                          D365Id: '@triggerBody()?[\'_customerid_value\']'
                        }
                      }
                      path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                    }
                  }
                }
                runAfter: {
                  Get_Order: [
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
                        '@length(body(\'Get_Order\')?[\'value\'])'
                        0
                      ]
                    }
                  ]
                }
                type: 'If'
              }
              Get_Order: {
                runAfter: {
                  Get_OmniSync_Configuration: [
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
                  path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items'
                  queries: {
                    '$filter': 'OrderNumber eq \'@{triggerBody()?[\'omnisync_salesforceordernumber\']}\''
                  }
                }
              }
              Get_OmniSync_Configuration: {
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
                  path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'omnisync_omnisyncconfigurations\'))}'
                }
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
