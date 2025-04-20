param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_sf_omnisync_accounts_name string = 'wf-d365-sf-omnisyncinc-accounts-${suffix}'
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''

resource wf_d365_sf_omnisync_accounts 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_sf_omnisync_accounts_name
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        integration_user: {
          defaultValue: 'integration@OmniSyncv1.onmicrosoft.com'
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
              entityname: 'account'
              message: 7
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
          runAfter: {}
          else: {
            actions: {
              Operation: {
                cases: {
                  Create: {
                    case: 'Create'
                    actions: {
                      Create_record: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            Name: 'kkkkkkkk'
                          }
                          path: '/v2/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items'
                        }
                      }
                    }
                  }
                  Update: {
                    case: 'Update'
                    actions: {
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
                            query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE FabricId=@FabricId AND Entity=\'Customer\'\n\n '
                            formalParameters: {
                              FabricId: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              FabricId: '19148'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                        }
                      }
                      'Update_record_(V3)': {
                        runAfter: {
                          Get_Mapped_SalesForceId_for_Update: [
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
                            Name: '@triggerBody()?[\'name\']'
                          }
                          path: '/v3/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Mapped_SalesForceId_for_Update\'))?[\'SalesForceId\']))}'
                        }
                      }
                    }
                  }
                  Delete: {
                    case: 'Delete'
                    actions: {
                      Delete_record: {
                        runAfter: {
                          Get_Mapped_SalesForceId_for_Delete: [
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
                          method: 'delete'
                          path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Account\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Mapped_SalesForceId_for_Delete\'))?[\'SalesForceId\']))}'
                        }
                      }
                      Get_Mapped_SalesForceId_for_Delete: {
                        type: 'ApiConnection'
                        inputs: {
                          host: {
                            connection: {
                              name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
                            }
                          }
                          method: 'post'
                          body: {
                            query: 'SELECT * \nFROM OmniSync_DE_LH_320_Gold_Contoso.dbo.MasterDataMapping\nWHERE FabricId=@FabricId AND Entity=\'Customer\'\n\n '
                            formalParameters: {
                              FabricId: 'NVARCHAR(100)'
                            }
                            actualParameters: {
                              FabricId: '19148'
                            }
                          }
                          path: '/v2/datasets/@{encodeURIComponent(encodeURIComponent(\'4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com\'))},@{encodeURIComponent(encodeURIComponent(\'OmniSync_DE_LH_320_Gold_Contoso\'))}/query/sql'
                        }
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
                    }
                  }
                }
                expression: '@triggerBody()?[\'SdkMessage\']'
                type: 'Switch'
              }
            }
          }
          expression: {
            or: [
              {
                equals: [
                  '@triggerBody()?[\'_createdby_value\']'
                  '@parameters(\'integration_user\')'
                ]
              }
              {
                equals: [
                  '@triggerBody()?[\'_modifiedby_value\']'
                  '@parameters(\'integration_user\')'
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
