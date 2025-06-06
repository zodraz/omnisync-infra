param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_accounts_name string = 'wf-sf-d365-omnisyncinc-accounts-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_accounts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_accounts_name
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
        When_a_HTTP_request_is_received: {
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
                    Name: {}
                    Type: {}
                    RecordTypeId: {}
                    ParentId: {}
                    BillingAddress: {}
                    ShippingAddress: {}
                    Phone: {}
                    Fax: {}
                    AccountNumber: {}
                    Website: {}
                    Sic: {}
                    Industry: {}
                    AnnualRevenue: {}
                    NumberOfEmployees: {}
                    Ownership: {}
                    TickerSymbol: {}
                    Description: {}
                    Rating: {}
                    Site: {}
                    CurrencyIsoCode: {}
                    OwnerId: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    SourceSystemIdentifier: {}
                    Jigsaw: {}
                    JigsawCompanyId: {}
                    AccountSource: {}
                    SicDesc: {}
                    OperatingHoursId: {}
                    Email__c: {}
                    Sync_Status__c: {}
                  }
                }
              }
            }
          }
        }
        Operation: {
          runAfter: {
            Parse_CDC_JSON: [
              'Succeeded'
            ]
          }
          cases: {
            Create: {
              case: 'CREATE'
              actions: {
                Get_Account_by_AccountNumber: {
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
                    path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}'
                    queries: {
                      '$filter': 'accountnumber eq \'@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']}\''
                    }
                  }
                }
                Check_if_Account_exists_in_D365: {
                  actions: {
                    Get_Mapped_D365Id_for_Insert: {
                      type: 'ApiConnection'
                      inputs: {
                        host: {
                          connection: {
                            name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                          }
                        }
                        method: 'post'
                        body: {
                          query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                          formalParameters: {
                            Name: 'NVARCHAR(100)'
                          }
                          actualParameters: {
                            Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']}'
                          }
                        }
                        path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                      }
                    }
                    Check_if_AccountNumber_exists_in_Fabric: {
                      actions: {
                        Update_Status_Conflict_Account: {
                          type: 'ApiConnection'
                          inputs: {
                            host: {
                              connection: {
                                name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                              }
                            }
                            method: 'patch'
                            body: {
                              Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                              SyncStatus__c: 'Conflict'
                            }
                            path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])))}'
                          }
                        }
                      }
                      runAfter: {
                        Get_Mapped_D365Id_for_Insert: [
                          'Succeeded'
                        ]
                      }
                      else: {
                        actions: {}
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
                  runAfter: {
                    Get_Account_by_AccountNumber: [
                      'Succeeded'
                    ]
                  }
                  else: {
                    actions: {
                      Add_a_new__Account: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                            accountnumber: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']}'
                            address1_city: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'City\']}'
                            address1_line1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Street\']}'
                            address1_postalcode: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'PostalCode\']}'
                            revenue: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AnnualRevenue\']'
                            telephone1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Phone\']}'
                            numberofemployees: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'NumberOfEmployees\']'
                            address1_country: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'State\']}'
                            address1_county: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Country\']}'
                            address1_fax: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Fax\']}'
                            address1_latitude: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Latitude\']'
                            address1_longitude: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ShippingAddress\']?[\'Longitude\']'
                            emailaddress1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Email__c\']}'
                            fax: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Fax\']}'
                            industrycode: 25
                          }
                          headers: {
                            prefer: 'return=representation,odata.include-annotations=*'
                            organization: 'https://org58211bdf.crm4.dynamics.com'
                          }
                          path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}'
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
                            query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\' AND SalesForceId IS NOT NULL'
                            formalParameters: {
                              Name: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']}'
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
                          Values: '{ "SalesForceId": "@{body(\'Get_Mapped_D365Id_for_Insert_to_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'SalesForceId\']}","D365IdToInsert": "@{body(\'Add_a_new__Account\')?[\'accountid\']}"}'
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
                      Delay_for_CDC_on_SalesForce_on_Fabric: {
                        runAfter: {
                          Add_a_new__Account: [
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
                    }
                  }
                  expression: {
                    and: [
                      {
                        greater: [
                          '@length(body(\'Get_Account_by_AccountNumber\')?[\'value\'])'
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
                Get_Mapped_D365Id_for_Update: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Customer\''
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
                'Check_if_Mapping_Customer_(for_Update)_row_exists_': {
                  actions: {}
                  runAfter: {
                    Get_Mapped_D365Id_for_Update: [
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
                          body: 'Account @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']} to delete not found on Dynamics365'
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
                            '@length(string(body(\'Get_Mapped_D365Id_for_Update\')?[\'resultsets\']))'
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
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Customer\''
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
                'Check_if_Mapping_Customer_(for_Delete)_row_exists': {
                  actions: {
                    Delete_Account: {
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
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_D365Id_for_Delete\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']))})'
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
                      'Response_Account_not_found_(on_Delete)': {
                        type: 'Response'
                        kind: 'Http'
                        inputs: {
                          statusCode: 404
                          body: 'Account @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'AccountNumber\']} - @{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']} to delete not found on Dynamics365'
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

output wf_sf_d365_omnisync_accounts_callbackurl string = listCallbackURL('${wf_sf_d365_omnisync_accounts.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
