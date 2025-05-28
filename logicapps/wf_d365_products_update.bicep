param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_products_name string = 'wf-d365-omnisyncinc-products-update-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_d365_omnisync_products_update 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_products_name
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
                name: '@parameters(\'$connections\')[\'commondataservice-1\'][\'connectionId\']'
              }
            }
            body: {
              entityname: 'product'
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
                          name: 'D365ProductToProduct'
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
                    query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE D365Id=@D365Id AND Entity=\'Product\' AND SalesForceId IS NOT NULL'
                    formalParameters: {
                      D365Id: 'NVARCHAR(100)'
                    }
                    actualParameters: {
                      D365Id: '@triggerBody()?[\'productid\']'
                    }
                  }
                  path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                }
              }
              'Check_if_Mapping_Product_(for_Update)_row_exists_': {
                actions: {
                  Update_Product: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'patch'
                      body: {
                        Name: '@triggerBody()?[\'name\']'
                        ProductCode: '@triggerBody()?[\'productnumber\']'
                        IsActive: true
                        Family: '@triggerBody()?[\'_omnisync_category_label\']'
                        CurrencyIsoCode: 'EUR'
                        FamilyId__c: '@triggerBody()?[\'omnisync_category\']'
                        Manufacturer__c: '@triggerBody()?[\'omnisync_manufacturer\']'
                        Brand__c: '@triggerBody()?[\'omnisync_brand\']'
                        Class__c: '@triggerBody()?[\'_omnisync_class_label\']'
                        ClassId__c: '@triggerBody()?[\'omnisync_class\']'
                        ColorId__c: '@triggerBody()?[\'omnisync_color\']'
                        Color__c: '@triggerBody()?[\'_omnisync_color_label\']'
                        Size__c: '@triggerBody()?[\'size\']'
                        SizeUnitOfMeasure__c: '@triggerBody()?[\'_omnisync_sizeunitofmeasure_label\']'
                        SizeUnitOfMeasureId__c: '@triggerBody()?[\'omnisync_sizeunitofmeasure\']'
                        Weight__c: '@triggerBody()?[\'omnisync_weight\']'
                        WeightUnitOfMeasure__c: '@triggerBody()?[\'_omnisync_weightunitofmeasure_label\']'
                        WeightUnitOfMeasureId__c: '@triggerBody()?[\'omnisync_weightunitofmeasure\']'
                        AvailableForSaleDate__c: '@triggerBody()?[\'validfromdate\']'
                        StopSaleDate__c: '@triggerBody()?[\'validtodate\']'
                      }
                      path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Product2\'))}/items/@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_SalesForceId_for_Update\')?[\'ResultSets\'][\'Table1\'][0][\'SalesForceId\']))}'
                    }
                  }
                  Get_Standard_PriceBook_Entry_1: {
                    runAfter: {
                      Get_OmniSync_Configurations: [
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
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items'
                      queries: {
                        '$filter': 'Product2Id eq \'@{body(\'Update_Product\')?[\'Id\']}\' and Pricebook2Id eq \'@{first(body(\'Get_OmniSync_Configurations\')?[\'value\'])?[\'omnisync_sfpricebookstandardpricebook\']}\''
                      }
                    }
                  }
                  Update_PriceBook_Entry_1: {
                    runAfter: {
                      Get_Standard_PriceBook_Entry_1: [
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
                        UnitPrice: '@triggerBody()?[\'price\']'
                        IsActive: true
                        UseStandardPrice: false
                        UnitCost__c: '@triggerBody()?[\'currentcost\']'
                      }
                      path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Standard_PriceBook_Entry_1\')?[\'value\'])?[\'Id\']))}'
                    }
                  }
                  Get_OmniSync_Configurations: {
                    runAfter: {
                      Update_Product: [
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
                  Get_Standard_PriceBook_Entry_2: {
                    runAfter: {
                      Update_PriceBook_Entry_1: [
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
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items'
                      queries: {
                        '$filter': 'Product2Id eq \'@{body(\'Update_Product\')?[\'Id\']}\' and Pricebook2Id eq \'@{first(body(\'Get_OmniSync_Configurations\')?[\'value\'])?[\'omnisync_sfstandardpricebook\']}\''
                      }
                    }
                  }
                  Update_PriceBook_Entry_2: {
                    runAfter: {
                      Get_Standard_PriceBook_Entry_2: [
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
                        UnitPrice: '@triggerBody()?[\'price\']'
                        IsActive: true
                        UseStandardPrice: false
                        UnitCost__c: '@triggerBody()?[\'currentcost\']'
                      }
                      path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'PricebookEntry\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Standard_PriceBook_Entry_2\')?[\'value\'])?[\'Id\']))}'
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
                    'Response_Account_not_found_(on_Update)': {
                      type: 'Response'
                      kind: 'Http'
                      inputs: {
                        statusCode: 404
                        body: 'Account  @{triggerBody()?[\'accountnumber\']}- @{triggerBody()?[\'name\']} to update not found on Dynamics365'
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
