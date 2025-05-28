param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_orderproducts_insert_name string = 'wf-d365-omnisyncinc-orderproducts-insert-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_d365_omnisync_orderproducts_insert 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_orderproducts_insert_name
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
                      Operation: 'Create'
                      Entity: 'SalesOrders'
                      Values: '{ "D365Id": "@{triggerBody()?[\'salesorderdetailid\']}","DateKey": "@{formatDateTime(body(\'Get_Order\')?[\'requestdeliveryby\'], \'yyyy-MM-dd\')}","StoreKey": "@{body(\'Get_Order\')?[\'_cr989_retailstore_value\']}","ProductKey": "@{body(\'Get_Product\')?[\'productid\']}","CurrencyKey": "EUR","CustomerKey": "@{body(\'Get_Order\')?[\'_customerid_value\']}","SalesOrderNumber": "@{body(\'Get_Order\')?[\'ordernumber\']}","SalesOrderLineNumber": "@{triggerBody()?[\'omnisync_lineitemnumber\']}","SalesQuantity": "@{triggerBody()?[\'quantity\']}","UnitCost": "@{body(\'Get_Product\')?[\'currentcost\']}","UnitPrice": "@{triggerBody()?[\'priceperunit\']}","CreatedDate": "@{triggerBody()?[\'createdon\']}","UpdatedDate": "@{triggerBody()?[\'modifiedon\']}"}'
                      CreatedDate: '@utcNow()'
                      UpdatedDate: '@utcNow()'
                    }
                  }
                }
                runAfter: {
                  GetSalesForce__Product: [
                    'Succeeded'
                  ]
                }
                type: 'Scope'
              }
              Check_if_Order_exists_in_SalesForce: {
                actions: {
                  Create_SalesOrder: {
                    runAfter: {
                      Get_Price_Book_Entry: [
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
                        Quantity: '@triggerBody()?[\'quantity\']'
                        Product2Id: '@first(body(\'GetSalesForce__Product\')?[\'value\'])[\'Id\']'
                        OrderId: '@body(\'Get_Mapped_SalesForceId_for_Order\')?[\'resultsets\']?[\'Table1\']?[0]?[\'SalesForceId\']'
                        PricebookEntryId: '@first(body(\'Get_Price_Book_Entry\')?[\'value\'])?[\'Id\']'
                        UnitPrice: '@triggerBody()?[\'priceperunit\']'
                        ListPrice: '@triggerBody()?[\'priceperunit\']'
                        ServiceDate: '@body(\'Get_Order\')?[\'requestdeliveryby\']'
                        Description: '@triggerBody()?[\'salesorderdetailname\']'
                        OrderItemLineNumber__c: 50
                        CostPrice__c: '@body(\'Get_Product\')?[\'currentcost\']'
                      }
                      path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'OrderItem\'))}/items'
                    }
                  }
                  Delay_for_CDC_on_SalesForce_on_Fabric: {
                    runAfter: {
                      Create_SalesOrder: [
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
                        query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'SalesOrders\' AND D365Id IS NOT NULL'
                        formalParameters: {
                          Name: 'NVARCHAR(100)'
                        }
                        actualParameters: {
                          Name: '@{triggerBody()?[\'lineitemnumber\']}-@{body(\'Get_Order\')?[\'ordernumber\']}-'
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
                      Values: '{ "SalesForceIdToInsert": "@{body(\'Create_SalesOrder\')?[\'Id\']}","D365Id": "@{triggerBody()?[\'salesorderdetailid\']}"}'
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
                  Get_Price_Book_Entry: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'get'
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items'
                      queries: {
                        '$filter': 'Name eq \'@{body(\'Get_Product\')?[\'name\']}\' and Pricebook2Id eq \'@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_sfstandardpricebook\']}\''
                      }
                    }
                  }
                }
                runAfter: {
                  Get_Mapped_SalesForceId_for_Order: [
                    'Succeeded'
                  ]
                }
                else: {
                  actions: {
                    Update_Status_Order: {
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
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'salesorderid\']))})'
                      }
                    }
                  }
                }
                expression: {
                  and: [
                    {
                      not: {
                        equals: [
                          '@length(string(body(\'Get_Mapped_SalesForceId_for_Order\')?[\'resultsets\']))'
                          2
                        ]
                      }
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
                      name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                    }
                  }
                  method: 'get'
                  headers: {
                    prefer: 'odata.include-annotations=*'
                    accept: 'application/json;odata.metadata=full'
                    organization: 'https://org58211bdf.crm4.dynamics.com'
                  }
                  path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'_salesorderid_value\']))})'
                }
              }
              Get_Mapped_SalesForceId_for_Order: {
                runAfter: {
                  GetSalesForce__Product: [
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
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name = @Name AND Entity=\'Order\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                    formalParameters: {
                      Name: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      Name: '@body(\'Get_Order\')?[\'ordernumber\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              Get_Product: {
                runAfter: {
                  Get_Order: [
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
                  method: 'get'
                  headers: {
                    prefer: 'odata.include-annotations=*'
                    accept: 'application/json;odata.metadata=full'
                    organization: 'https://org58211bdf.crm4.dynamics.com'
                  }
                  path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'products\'))}(@{encodeURIComponent(encodeURIComponent(triggerBody()?[\'_productid_value\']))})'
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
              GetSalesForce__Product: {
                runAfter: {
                  Get_Product: [
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
                  path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Product2\'))}/items'
                  queries: {
                    '$filter': ' ProductCode eq \'@{body(\'Get_Product\')?[\'productnumber\']}\''
                  }
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
