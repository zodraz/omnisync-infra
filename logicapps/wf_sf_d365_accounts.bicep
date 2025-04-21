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
        }
      }
      actions: {
        Parse_CDC_JSON: {
          runAfter: {
            Initialize_CDC_record: [
              'Succeeded'
            ]
          }
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
                    cgcloud__Account_Email__c: {}
                    cgcloud__Account_Number__c: {}
                    cgcloud__Account_Template__c: {}
                    cgcloud__ExternalId__c: {}
                    cgcloud__Name_2__c: {}
                    cgcloud__Number_Of_Extensions__c: {}
                    SDO_Sales_Closed_Won_Value__c: {}
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
              case: 'Create'
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
                      query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Customer\''
                      formalParameters: {
                        Name: 'NVARCHAR(100)'
                      }
                      actualParameters: {
                        Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'cgcloud__Account_Number__c\']}'
                      }
                    }
                    path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                  }
                }
                Check_if_AccountNumber_exists_in_D365: {
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
                          accountnumber: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'cgcloud__Account_Number__c\']}'
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
                          emailaddress1: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'cgcloud__Account_Email__c\']}'
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
                  }
                  runAfter: {
                    Get_Mapped_D365Id_for_Insert: [
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
                              name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                            }
                          }
                          method: 'patch'
                          body: {
                            Name: '@{body(\'Parse_CDC_JSON\')?[\'payload\']?[\'Name\']}'
                            Sync_Status__c: 'Conflict'
                          }
                          path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])))}'
                        }
                      }
                    }
                  }
                  expression: {
                    and: [
                      {
                        equals: [
                          '@lenght(body(\'Get_Mapped_D365Id_for_Insert\'))'
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
              case: 'Update'
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
                Update_an_Account: {
                  runAfter: {
                    Get_Mapped_D365Id_for_Update: [
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
                    headers: {
                      prefer: 'return=representation,odata.include-annotations=*'
                      accept: 'application/json;odata.metadata=full'
                      organization: 'https://org58211bdf.crm4.dynamics.com'
                    }
                    path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Mapped_D365Id_for_Update\')?[\'D365\'])))})'
                  }
                }
              }
            }
            Delete: {
              case: 'Delete'
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
                Get_Orders: {
                  runAfter: {
                    Get_Mapped_D365Id_for_Delete: [
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
                      '$filter': 'account eq @{first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])}'
                    }
                  }
                }
                For_each_order: {
                  foreach: '@body(\'Get_Orders\')?[\'value\']'
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
                        path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'salesorders\'))}(@{encodeURIComponent(encodeURIComponent(item()?[\'@odata.id\']))})'
                      }
                    }
                  }
                  runAfter: {
                    Get_Orders: [
                      'Succeeded'
                    ]
                  }
                  type: 'Foreach'
                }
                Delete_Account: {
                  runAfter: {
                    For_each_order: [
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
                    method: 'delete'
                    headers: {
                      organization: 'https://org58211bdf.crm4.dynamics.com'
                    }
                    path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'accounts\'))}(@{encodeURIComponent(encodeURIComponent(first(body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'recordIds\'])))})'
                  }
                }
              }
            }
          }
          default: {
            actions: {}
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
