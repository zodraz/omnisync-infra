param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_orderproducts_delete_name string = 'wf-d365-omnisyncinc-orderproducts-delete-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_d365_omnisync_orderproducts_delete 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_orderproducts_delete_name
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
              entityname: 'salesorderdetail'
              message: 2
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
                  Send_CDC_event: {
                    runAfter: {
                      Create_CDC_Fabric: [
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
                        ContentData: '@base64(outputs(\'Create_CDC_Fabric\'))'
                      }
                      path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
                      queries: {
                        partitionKey: '0'
                      }
                    }
                  }
                  Create_CDC_Fabric: {
                    type: 'Compose'
                    inputs: {
                      Operation: 'Delete'
                      Entity: 'SalesOrders'
                      Values: '{ "D365Id": "@{triggerBody()?[\'salesorderdetailid\']}","DateKey": "","StoreKey": "","ProductKey": "","CurrencyKey": "EUR","CustomerKey": "","SalesOrderNumber": "", "CreatedDate":"@{utcNow()}","UpdatedDate": "@{utcNow()}"}'
                      CreatedDate: '@utcNow()'
                      UpdatedDate: '@utcNow()'
                    }
                  }
                }
                type: 'Scope'
              }
              Get_Mapped_SalesForceId_for_SalesOrder: {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                    }
                  }
                  method: 'post'
                  body: {
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE D365Id= @D365Id AND Entity=\'SalesOrders\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                    formalParameters: {
                      D365Id: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      D365Id: '@triggerBody()?[\'salesorderdetailid\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              Check_if_Mapping_SalesOrder_row_exists_: {
                actions: {
                  Delete_SalesOrder: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'delete'
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'OrderItem\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_SalesForceId_for_SalesOrder\')?[\'ResultSets\'][\'Table1\'][0][\'SalesForceId\']))}'
                    }
                  }
                }
                runAfter: {
                  Get_Mapped_SalesForceId_for_SalesOrder: [
                    'Succeeded'
                  ]
                }
                else: {
                  actions: {
                    Response_SalesOrders_not_found: {
                      type: 'Response'
                      kind: 'Http'
                      inputs: {
                        statusCode: 404
                        body: 'SalesOrder with D365Id  @{triggerBody()?[\'salesorderdetailid\']} to delete not found on Dynamics365'
                      }
                    }
                  }
                }
                expression: {
                  and: [
                    {
                      not: {
                        equals: [
                          '@length(string(body(\'Get_Mapped_SalesForceId_for_SalesOrder\')?[\'resultsets\']))'
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
          runAfter: {}
          type: 'Scope'
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
