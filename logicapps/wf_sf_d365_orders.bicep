param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_orders_name string = 'wf-sf-d365-omnisyncinc-orders-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_orders 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_orders_name
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
                    OwnerId: {}
                    ContractId: {}
                    AccountId: {}
                    Pricebook2Id: {}
                    OriginalOrderId: {}
                    OpportunityId: {}
                    EffectiveDate: {}
                    EndDate: {}
                    IsReductionOrder: {}
                    Status: {}
                    Description: {}
                    CustomerAuthorizedById: {}
                    CustomerAuthorizedDate: {}
                    CompanyAuthorizedById: {}
                    CompanyAuthorizedDate: {}
                    Type: {}
                    BillingAddress: {}
                    ShippingAddress: {}
                    Name: {}
                    PoDate: {}
                    PoNumber: {}
                    OrderReferenceNumber: {}
                    BillToContactId: {}
                    ShipToContactId: {}
                    ActivatedDate: {}
                    ActivatedById: {}
                    StatusCode: {}
                    CurrencyIsoCode: {}
                    OrderNumber: {}
                    TotalAmount: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    SyncStatus__c: {}
                    D365OrderNumber__c: {}
                    NumLineItems__c: {}
                    RetailStore__c: {}
                  }
                }
              }
            }
          }
        }
        Operation: {
          runAfter: {
            Get_Mapped_D365Id_for_Account: [
              'Succeeded'
            ]
          }
          cases: {
            Create: {
              case: 'CREATE'
              actions: {
                Check_if_Order_exists_in_D365: {
                  actions: {
                    Get_Order_to_Update_Conflict: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                          }
                        }
                        method: 'get'
                        path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])))}'
                      }
                    }
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
                  }
                  else: {
                    actions: {
                      Add_a_new__Order: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            'transactioncurrencyid@odata.bind': 'transactioncurrencies(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_d365currency\']})'
                            name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                            'pricelevelid@odata.bind': 'pricelevels(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_d365productdefaultpricelist\']})'
                            requestdeliveryby: '@formatDateTime(addToTime(\'1970-01-01T00:00:00Z\',div(int(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'EffectiveDate\']),1000), \'Second\'), \'yyyy-MM-dd\')'
                            'cr989_RetailStore@odata.bind': 'cr989_retailstores(@{body(\'Get_Mapped_D365Id_for_RetailStore\')?[\'resultsets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                            'customerid_account@odata.bind': 'accounts(@{body(\'Get_Mapped_D365Id_for_Account\')?[\'resultsets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                            ordernumber: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderNumber\']}'
                            willcall: true
                          }
                          headers: {
                            prefer: 'return=representation,odata.include-annotations=*'
                            organization: 'https://org58211bdf.crm4.dynamics.com'
                          }
                          path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}'
                        }
                      }
                      Create_CDC_Store: {
                        runAfter: {
                          Add_a_new__Order: [
                            'Succeeded'
                          ]
                        }
                        type: 'Compose'
                        inputs: {
                          Operation: 'Create'
                          Entity: 'MasterDataMapping'
                          Values: '{ "SalesForceId": "@{first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])}","D365Id": "@{body(\'Add_a_new__Order\')?[\'salesorderid\']}","Entity":"Order","Name":"@{body(\'Add_a_new__Order\')?[\'ordernumber\']}","CreatedDate":"@{utcNow()}","UpdatedDate":"@{utcNow()}"}'
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
            }
            Update: {
              case: 'UPDATE'
              actions: {
                'Check_if_Order_exists_in_D365_(for_Update)_row_exists_': {
                  actions: {
                    Update_an_Order: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                          }
                        }
                        method: 'patch'
                        body: {
                          'customerid_account@odata.bind': 'accounts(@{body(\'Get_Mapped_D365Id_for_Account\')?[\'resultsets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                          name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                          'pricelevelid@odata.bind': 'pricelevels(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_d365productdefaultpricelist\']})'
                          requestdeliveryby: '@formatDateTime(addToTime(\'1970-01-01T00:00:00Z\',div(int(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'EffectiveDate\']),1000), \'Second\'), \'yyyy-MM-dd\')'
                          'cr989_RetailStore@odata.bind': 'cr989_retailstores(@{body(\'Get_Mapped_D365Id_for_RetailStore\')?[\'resultsets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                        }
                        headers: {
                          prefer: 'return=representation,odata.include-annotations=*'
                          accept: 'application/json;odata.metadata=full'
                          organization: 'https://org58211bdf.crm4.dynamics.com'
                        }
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Order_by_OrderNumber\')?[\'value\'])?[\'salesorderid\']))})'
                      }
                    }
                  }
                  else: {
                    actions: {
                      'Response_Order_not_found_(on_Update)': {
                        type: 'Response'
                        kind: 'Http'
                        inputs: {
                          statusCode: 404
                          body: 'Order @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderNumber\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}  to update not found on Dynamics365'
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
                            '@length(body(\'Get_Order_by_OrderNumber\')?[\'value\'])'
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
                'Check_if_Order_(for_Delete)_row_exists': {
                  actions: {
                    Delete_Order: {
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
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Order_by_OrderNumber\')?[\'value\'])?[\'salesorderid\']))})'
                      }
                    }
                  }
                  else: {
                    actions: {
                      'Response_Order_not_found_(on_Delete)': {
                        type: 'Response'
                        kind: 'Http'
                        inputs: {
                          statusCode: 404
                          body: 'Order @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderNumber\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}  to delete not found on Dynamics365'
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
                            '@length(body(\'Get_Order_by_OrderNumber\')?[\'value\'])'
                            0
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
        Get_Order_by_OrderNumber: {
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
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}'
            queries: {
              '$filter': 'ordernumber eq \'@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'OrderNumber\']}\''
            }
          }
        }
        Get_Mapped_D365Id_for_RetailStore: {
          runAfter: {
            Get_Order_by_OrderNumber: [
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
              query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Store\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
              formalParameters: {
                SalesForceId: 'NVARCHAR(100)'
              }
              actualParameters: {
                SalesForceId: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'RetailStore__c\']}'
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
                SalesForceId: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountId\']}'
              }
            }
            path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
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

output wf_sf_d365_omnisync_orders_callbackurl string = listCallbackURL('${wf_sf_d365_omnisync_orders.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
