param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_orderproducts_name string = 'wf-sf-d365-omnisyncinc-orderproducts-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_orderproducts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_orderproducts_name
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
        When_a_HTTP_request__is_received: {
          type: 'Request'
          kind: 'Http'
          runtimeConfiguration: {
            concurrency: {
              runs: 1
            }
          }
        }
      }
      actions: {
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
                        }
                      }
                    }
                    Product2Id: {}
                    OrderId: {}
                    PricebookEntryId: {}
                    OriginalOrderItemId: {}
                    QuoteLineItemId: {}
                    AvailableQuantity: {}
                    Quantity: {}
                    CurrencyIsoCode: {}
                    UnitPrice: {}
                    ListPrice: {}
                    ServiceDate: {}
                    EndDate: {}
                    Description: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    OrderItemNumber: {}
                    QuantityUnitOfMeasureId: {}
                    CostPrice__c: {}
                  }
                }
              }
            }
          }
        }
        Operation: {
          runAfter: {
            Check_if_Order_exists_in_D365: [
              'Succeeded'
            ]
          }
          cases: {
            Create: {
              case: 'CREATE'
              actions: {
                Get_Mapped_D365Id_for_RetailStore: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Store\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                      formalParameters: {
                        SalesForceId: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        SalesForceId: '@body(\'Get_Order\')[\'RetailStore__c\']'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                Get_Mapped_D365Id_for_Account: {
                  runAfter: {
                    Get_Mapped_D365Id_for_RetailStore: [
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
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Customer\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                      formalParameters: {
                        SalesForceId: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        SalesForceId: '@body(\'Get_Order\')?[\'AccountId\']'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                Get_Mapped_D365Id_for_Insert: {
                  runAfter: {
                    Get_Mapped_D365Id_for_Account: [
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
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'SalesOrders\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                      formalParameters: {
                        Name: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        Name: '@concat(body(\'Get_Order\')?[\'OrderNumber\'],\'-\',body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemNumber\'])'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                Get_Mapped_D365Id_for_Product: {
                  runAfter: {
                    Get_Mapped_D365Id_for_Insert: [
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
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Product\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                      formalParameters: {
                        SalesForceId: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        SalesForceId: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Product2Id\']}'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                Check_if_Order_exists_in_Fabric: {
                  actions: {
                    Update_Status_Conflict_Order: {
                      runAfter: {
                        Get_Order_to_Update_Conflict: [
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
                          EffectiveDate: '@body(\'Get_Order_to_Update_Conflict\')[\'EffectiveDate\']'
                          Status: 'Activated'
                          RetailStore__c: '@body(\'Get_Order_to_Update_Conflict\')[\'RetailStore__c\']'
                          Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                          SyncStatus__c: 'Conflict'
                        }
                        path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Get_Order_to_Update_Conflict\')?[\'Id\']))}'
                      }
                    }
                    Get_Order_to_Update_Conflict: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                          }
                        }
                        method: 'get'
                        path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_D365Id_for_Insert\')?[\'resultsets\']?[0]?[\'SalesForceId\']))}'
                      }
                    }
                  }
                  runAfter: {
                    Get_Mapped_D365Id_for_Product: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      Add_a_new_Order_Product: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            salesorderdetailname: '@concat(body(\'Get_Order\')?[\'OrderNumber\'],\'-\',body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemLineNumber__c\'])'
                            quantity: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Quantity\']'
                            'productid@odata.bind': 'products(@{body(\'Get_Mapped_D365Id_for_Product\')?[\'resultsets\']?[\'Table1\'][0]?[\'D365Id\']})'
                            'salesorderid@odata.bind': 'salesorders(@{first(body(\'Get_Order_by_OrderNumber\')?[\'value\'])?[\'salesorderid\']})'
                            priceperunit: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitPrice\']'
                            ispriceoverridden: true
                            producttypecode: 1
                            'uomid@odata.bind': 'uoms(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_D365ProductDefaultUnit\']})'
                            lineitemnumber: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemLineNumber__c\']'
                          }
                          headers: {
                            prefer: 'return=representation,odata.include-annotations=*'
                            organization: 'https://org58211bdf.crm4.dynamics.com'
                          }
                          path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorderdetails\'))}'
                        }
                      }
                      Delay_for_CDC_on_SalesForce_on_Fabric: {
                        runAfter: {
                          Add_a_new_Order_Product: [
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
                      Get_Mapped_D365Id_for_Insert_to_Update___TO_DELETE: {
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
                            query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'SalesOrders\' AND SalesForceId IS NOT NULL'
                            formalParameters: {
                              Name: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              Name: '@concat(body(\'Get_Order\')?[\'OrderNumber\'],\'-\',body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemNumber\'])'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                        }
                      }
                      Create_CDC_Store: {
                        runAfter: {
                          Get_Mapped_D365Id_for_Insert_to_Update___TO_DELETE: [
                            'Succeeded'
                          ]
                        }
                        type: 'Compose'
                        inputs: {
                          Operation: 'Update'
                          Entity: 'MasterDataMapping'
                          Values: '{ "SalesForceId": "@{first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])}","D365IdToInsert": "@{body(\'Add_a_new_Order_Product\')?[\'salesorderdetailid\']}"}'
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
                    }
                  }
                  expression: {
                    and: [
                      {
                        not: {
                          equals: [
                            '@length(string(body(\'Get_Mapped_D365Id_for_Insert\')?[\'resultsets\']))'
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
            Update: {
              case: 'UPDATE'
              actions: {
                Get_Mapped_D365Id_for_SalesOrders_Update: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'SalesOrders\''
                      formalParameters: {
                        SalesForceId: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        SalesForceId: '@first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                'Check_if_Mapping_Product_(for_Update)_row_exists_': {
                  actions: {
                    Update_a_row: {
                      runAfter: {
                        Get_Mapped_D365Id_for_Product_Update: [
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
                        method: 'patch'
                        body: {
                          'productid@odata.bind': 'products(@{body(\'Get_Mapped_D365Id_for_Product_Update\')?[\'resultsets\']?[\'Table1\']?[0][\'D365Id\']})'
                          salesorderdetailname: '@concat(body(\'Get_Order\')?[\'OrderNumber\'],\'-\',body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemLineNumber__c\'])'
                          'salesorderid@odata.bind': 'salesorders(@{first(body(\'Get_Order_by_OrderNumber\')?[\'value\'])?[\'salesorderid\']})'
                          priceperunit: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitPrice\']'
                          quantity: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Quantity\']'
                          'uomid@odata.bind': 'uoms(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_D365ProductDefaultUnit\']})'
                          baseamount: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitPrice\']'
                          lineitemnumber: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemLineNumber__c\']'
                        }
                        headers: {
                          prefer: 'return=representation,odata.include-annotations=*'
                          accept: 'application/json;odata.metadata=full'
                          organization: 'https://org58211bdf.crm4.dynamics.com'
                        }
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorderdetails\'))}(@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_D365Id_for_SalesOrders_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']))})'
                      }
                    }
                    Get_Mapped_D365Id_for_Product_Update: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                          }
                        }
                        method: 'post'
                        body: {
                          query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Product\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                          formalParameters: {
                            SalesForceId: 'NVARCHAR(100)'
                          }
                          actualParameters: {
                            SalesForceId: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Product2Id\']}'
                          }
                        }
                        path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                      }
                    }
                  }
                  runAfter: {
                    Get_Mapped_D365Id_for_SalesOrders_Update: [
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
                          body: 'Product @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ProductCode\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']} to update not found on Dynamics365'
                        }
                        operationOptions: 'Asynchronous'
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        not: {
                          equals: [
                            '@length(string(body(\'Get_Mapped_D365Id_for_SalesOrders_Update\')?[\'resultsets\']))'
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
              case: 'DELETE'
              actions: {
                Get_Mapped_D365Id_for_Delete: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'SalesOrders\''
                      formalParameters: {
                        SalesForceId: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        SalesForceId: '@first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                'Check_if_Mapping_SalesOrder(for_Delete)_row_exists': {
                  actions: {
                    Delete_Order_Product: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                          }
                        }
                        method: 'delete'
                        headers: {
                          organization: 'https://org58211bdf.crm4.dynamics.com'
                        }
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorderdetails\'))}(@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_D365Id_for_Delete\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']))})'
                      }
                    }
                  }
                  runAfter: {
                    Get_Mapped_D365Id_for_Delete: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      'Response_Product_not_found_(on_Delete)': {
                        type: 'Response'
                        kind: 'Http'
                        inputs: {
                          statusCode: 404
                          body: 'SalesOrder @{body(\'Get_Order\')?[\'OrderNumber\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderItemNumber\']} to delete not found on Dynamics365'
                        }
                        operationOptions: 'Asynchronous'
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        not: {
                          equals: [
                            '@length(string(body(\'Get_Mapped_D365Id_for_Delete\')?[\'resultsets\']))'
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
                operationOptions: 'Asynchronous'
              }
            }
          }
          expression: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'changeType\']'
          type: 'Switch'
        }
        Get_OmniSync_Configuration: {
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
            method: 'get'
            headers: {
              prefer: 'odata.include-annotations=*'
              accept: 'application/json;odata.metadata=full'
              organization: 'https://org58211bdf.crm4.dynamics.com'
            }
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'omnisync_omnisyncconfigurations\'))}'
          }
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
            path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderId\']))}'
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
                name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Product2\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Product2Id\']))}'
          }
        }
        Get_Order_by_OrderNumber: {
          runAfter: {
            Get_Product: [
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
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}'
            queries: {
              '$filter': 'ordernumber eq \'@{body(\'Get_Order\')?[\'OrderNumber\']}\''
            }
          }
        }
        Check_if_Order_exists_in_D365: {
          actions: {}
          runAfter: {
            Get_Order_by_OrderNumber: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
              Response_Order_not_found: {
                type: 'Response'
                kind: 'Http'
                inputs: {
                  statusCode: 404
                  body: 'SalesOrder @{body(\'Get_Order\')?[\'OrderNumber\']} not found on Dynamics365'
                }
                operationOptions: 'Asynchronous'
              }
              Terminate: {
                runAfter: {
                  Response_Order_not_found: [
                    'Succeeded'
                  ]
                }
                type: 'Terminate'
                inputs: {
                  runStatus: 'Failed'
                  runError: {
                    code: '404'
                    message: 'SalesOrder @{body(\'Get_Order\')?[\'OrderNumber\']} to insert not found on Dynamics365'
                  }
                }
              }
            }
          }
          expression: {
            and: [
              {
                greater: [
                  '@length(body(\'Get_Order_by_OrderNumber\')?[\'value\'])'
                  0
                ]
              }
            ]
          }
          type: 'If'
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

output wf_sf_d365_omnisync_orderproducts_callbackurl string = listCallbackURL('${wf_sf_d365_omnisync_orderproducts.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
