param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_sf_d365_omnisync_pricebooks_name string = 'wf-sf-d365-omnisyncinc-pricebooks-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_sf_d365_omnisync_pricebooks 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_sf_d365_omnisync_pricebooks_name
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
                    Pricebook2Id: {}
                    Product2Id: {}
                    CurrencyIsoCode: {}
                    UnitPrice: {}
                    IsActive: {}
                    UseStandardPrice: {}
                    CreatedDate: {}
                    CreatedById: {}
                    LastModifiedDate: {}
                    LastModifiedById: {}
                    IsArchived: {}
                    UnitCost__c: {}
                  }
                }
              }
            }
          }
        }
        Condition: {
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
                  query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE SalesForceId=@SalesForceId AND Entity=\'Product\''
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
            'Check_if_Mapping_Product_(for_Update)_row_exists_': {
              actions: {
                Update_Product: {
                  runAfter: {
                    Add_Price_List_Item: [
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
                      currentcost: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitCost__c\']'
                      price: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitPrice\']'
                      standardcost: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitCost__c\']'
                    }
                    headers: {
                      prefer: 'return=representation,odata.include-annotations=*'
                      accept: 'application/json;odata.metadata=full'
                      organization: 'https://org58211bdf.crm4.dynamics.com'
                    }
                    path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'products\'))}(@{encodeURIComponent(encodeURIComponent(body(\'Get_Mapped_D365Id_for_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']))})'
                  }
                }
                Add_Price_List_Item: {
                  type: 'ApiConnection'
                  inputs: {
                    host: {
                      connection: {
                        name: '@parameters(\'$connections\')[\'commondataservice\'][\'connectionId\']'
                      }
                    }
                    method: 'post'
                    body: {
                      amount: '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'UnitPrice\']'
                      percentage: 100
                      pricingmethodcode: 1
                      quantitysellingcode: 2
                      roundingoptionamount: 100
                      roundingoptioncode: 1
                      roundingpolicycode: 2
                      'uomid@odata.bind': 'uoms(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_d365productdefaultunit\']})'
                      'pricelevelid@odata.bind': 'pricelevels(@{first(body(\'Get_OmniSync_Configuration\')?[\'value\'])?[\'omnisync_d365productdefaultpricelist\']})'
                      'productid@odata.bind': 'products(@{body(\'Get_Mapped_D365Id_for_Update\')?[\'ResultSets\']?[\'Table1\']?[0]?[\'D365Id\']})'
                    }
                    headers: {
                      prefer: 'return=representation,odata.include-annotations=*'
                      organization: 'https://org58211bdf.crm4.dynamics.com'
                    }
                    path: '/api/data/v9.1/@{encodeURIComponent(encodeURIComponent(\'productpricelevels\'))}'
                  }
                }
              }
              runAfter: {
                Get_Mapped_D365Id_for_Update: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {
                  'Response_Product_not_found_(on_Update)': {
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
          runAfter: {
            Get_OmniSync_Configuration: [
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
                    '@body(\'Parse_CDC_JSON\')?[\'payload\']?[\'ChangeEventHeader\']?[\'changeType\']'
                    'Delete'
                  ]
                }
              }
            ]
          }
          type: 'If'
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

output wf_sf_d365_omnisync_pricebooks_callbackurl string = listCallbackURL('${wf_sf_d365_omnisync_pricebooks.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
