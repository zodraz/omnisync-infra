param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_retailstores_name string = 'wf-sf-d365-omnisyncinc-retailstores-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_retailstores 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_retailstores_name
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
            content: '@triggerBody()'
            schema: {
              type: 'object'
              properties: {
                notifications: {
                  type: 'object'
                  properties: {
                    '@@xmlns': {
                      type: 'string'
                    }
                    OrganizationId: {
                      type: 'string'
                    }
                    ActionId: {
                      type: 'string'
                    }
                    SessionId: {
                      type: 'object'
                      properties: {
                        '@@xsi:nil': {
                          type: 'string'
                        }
                        '@@xmlns:xsi': {
                          type: 'string'
                        }
                      }
                    }
                    EnterpriseUrl: {
                      type: 'string'
                    }
                    PartnerUrl: {
                      type: 'string'
                    }
                    Notification: {
                      type: 'object'
                      properties: {
                        Id: {
                          type: 'string'
                        }
                        sObject: {
                          type: 'object'
                          properties: {
                            '@@xsi:type': {
                              type: 'string'
                            }
                            '@@xmlns:sf': {
                              type: 'string'
                            }
                            '@@xmlns:xsi': {
                              type: 'string'
                            }
                            'sf:AccountId__c': {}
                            'sf:Address__City__s': {}
                            'sf:Address__CountryCode__s': {}
                            'sf:Address__GeocodeAccuracy__s': {}
                            'sf:Address__Latitude__s': {}
                            'sf:Address__Longitude__s': {}
                            'sf:Address__PostalCode__s': {}
                            'sf:Address__StateCode__s': {}
                            'sf:Address__Street__s': {}
                            'sf:CreatedById': {}
                            'sf:CreatedDate': {}
                            'sf:CurrencyIsoCode': {}
                            'sf:Description__c': {}
                            'sf:EmployeeCount__c': {}
                            'sf:Fax__c': {}
                            'sf:Id': {}
                            'sf:IsDeleted': {}
                            'sf:LastActivityDate': {}
                            'sf:LastModifiedById': {}
                            'sf:LastModifiedDate': {}
                            'sf:LastReferencedDate': {}
                            'sf:LastViewedDate': {}
                            'sf:Name': {}
                            'sf:OwnerId': {}
                            'sf:Phone__c': {}
                            'sf:StoreCode__c': {}
                            'sf:StoreTypeId__c': {}
                            'sf:StoreType__c': {}
                            'sf:SyncStatus__c': {}
                            'sf:SystemModstamp': {}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        Operation: {
          runAfter: {
            Check_if_RetailStore_exists_in_D365: [
              'Succeeded'
            ]
          }
          cases: {
            Create: {
              case: 'CREATE'
              actions: {}
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
        Get_RetailStore_by_Code: {
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
            path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'cr989_retailstores\'))}'
            queries: {
              '$filter': 'cr989_storecode eq \'@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}\''
            }
          }
        }
        Check_if_RetailStore_exists_in_D365: {
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
                  query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Store\' AND SalesForceId IS NOT NULL AND D365Id IS NOT NULL'
                  formalParameters: {
                    Name: 'NVARCHAR(100)'
                  }
                  actualParameters: {
                    Name: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}'
                  }
                }
                path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
              }
            }
            Check_if_RetailStore_exists_in_Fabric: {
              actions: {
                Update_Status_Conflict_RetailStore: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                      }
                    }
                    method: 'patch'
                    body: {
                      AccountId__c: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:AccountId__c\']}'
                      StoreType__c: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreTypeId__c\']}'
                      StoreCode__c: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}'
                      SyncStatus__c: 'Conflict'
                    }
                    path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'RetailStore__c\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Id\']))}'
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
            Get_RetailStore_by_Code: [
              'Succeeded'
            ]
          }
          else: {
            actions: {
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
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE Name=@Name AND Entity=\'Store\' AND SalesForceId IS NOT NULL'
                    formalParameters: {
                      Name: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      Name: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}'
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
                  Values: '{ "SalesForceId": "@{body(\'Get_Mapped_D365Id_for_Insert_to_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'SalesForceId\']}","D365IdToInsert": "@{body(\'Add_a_new__RetailStore\')?[\'cr989_retailstoreid\']}"}'
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
                  Add_a_new__RetailStore: [
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
              Add_a_new__RetailStore: {
                runAfter: {
                  Get_Mapped_D365Id_for_Account: [
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
                  method: 'post'
                  body: {
                    cr989_storecode: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreCode__c\']}'
                    cr989_storename: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Name\']}'
                    'cr989_Account_account@odata.bind': 'accounts(@{body(\'Get_Mapped_D365Id_for_Account\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                    cr989_address1_city: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__City__s\']}'
                    cr989_address1_country: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__CountryCode__s\']}'
                    cr989_address1_stateorprovince: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__StateCode__s\']}'
                    cr989_address1_street: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__Street__s\']}'
                    cr989_address1_postalcode: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__PostalCode__s\']}'
                    cr989_storedescription: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Description__c\']}'
                    cr989_storephone: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Phone__c\']}'
                    cr989_storetype: '@body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:StoreTypeId__c\']'
                    cr989_employeecount: '@body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:EmployeeCount__c\']'
                    cr989_storefax: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Fax__c\']}'
                    cr989_latitude: '@body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__Latitude__s\']'
                    cr989_longitude: '@body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:Address__Longitude__s\']'
                  }
                  headers: {
                    prefer: 'return=representation,odata.include-annotations=*'
                    organization: 'https://org58211bdf.crm4.dynamics.com'
                  }
                  path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'cr989_retailstores\'))}'
                }
              }
              Get_Mapped_D365Id_for_Account: {
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
                      SalesForceId: '@{body(\'Parse_CDC_JSON\')?[\'notifications\']?[\'Notification\']?[\'sObject\']?[\'sf:AccountId__c\']}'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
            }
          }
          expression: {
            and: [
              {
                greater: [
                  '@length(body(\'Get_RetailStore_by_Code\')?[\'value\'])'
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
