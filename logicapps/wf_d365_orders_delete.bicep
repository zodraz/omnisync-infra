param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param wf_d365_omnisync_orders_delete_name string = 'wf-d365-omnisyncinc-orders-delete-${suffix}'
param ia_omnisync_id string=''
param connections_salesforce_id string=''
param connections_sql_id string=''
param connections_cds_id string=''
param d365_organization string=''
param integration_user string=''
param database string =''
param sql_connection_string string = ''

resource wf_d365_omnisync_orders_delete 'Microsoft.Logic/workflows@2019-05-01' = {
  name: wf_d365_omnisync_orders_delete_name
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
              entityname: 'salesorder'
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
              Check_if_Mapping_Order_row_exists_: {
                actions: {
                  Delete_Account: {
                    type: 'ApiConnection'
                    inputs: {
                      host: {
                        connection: {
                          name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                        }
                      }
                      method: 'delete'
                      path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items/@{encodeURIComponent(encodeURIComponent(first(body(\'Get_Order\')?[\'value\'])?[\'Id\']))}'
                    }
                  }
                }
                runAfter: {
                  Get_Order: [
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
                        body: 'Order with D365Id  @{triggerBody()?[\'omnisync_salesforceordernumber\']} to delete not found on Dynamics365'
                      }
                    }
                  }
                }
                expression: {
                  and: [
                    {
                      not: {
                        equals: [
                          '@length(body(\'Get_Order\')?[\'value\'])'
                          0
                        ]
                      }
                    }
                  ]
                }
                type: 'If'
              }
              Get_Order: {
                type: 'ApiConnection'
                inputs: {
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'salesforce\'][\'connectionId\']'
                    }
                  }
                  method: 'get'
                  path: '/datasets/default/tables/@{encodeURIComponent(encodeURIComponent(\'Order\'))}/items'
                  queries: {
                    '$filter': 'OrderNumber eq \'@{triggerBody()?[\'omnisync_salesforceordernumber\']}\''
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
