// param env string = 'prod'
// param location_abbreviation string ='ne'
// param resource_number string='01'
// param suffix string = '${env}-${location_abbreviation}-${resource_number}'
// param location string ='northeurope'
// param wf_sf_fabric_omnisync_orderdetails_delete_name string = 'wf-sf-fabric-omnisync-orderdetails-delete-${suffix}'
// param connections_eventhubs_id string=''

// resource wf_sf_fabric_omnisync_orderdetails_delete 'Microsoft.Logic/workflows@2019-05-01' = {
//   name: wf_sf_fabric_omnisync_orderdetails_delete_name
//   location: location
//   properties: {
//     state: 'Enabled'
//     definition: {
//       '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
//       contentVersion: '1.0.0.0'
//       parameters: {
//         '$connections': {
//           defaultValue: {}
//           type: 'Object'
//         }
//       }
//       triggers: {
//         When_a_HTTP_request_is_received: {
//           type: 'Request'
//           kind: 'Http'
//         }
//       }
//       actions: {
//         Send__CDC_event: {
//           runAfter: {
//             Create_CDC_SalesOrder_record: [
//               'Succeeded'
//             ]
//           }
//           type: 'ApiConnection'
//           inputs: {
//             host: {
//               connection: {
//                 name: '@parameters(\'$connections\')[\'eventhubs\'][\'connectionId\']'
//               }
//             }
//             method: 'post'
//             body: {
//               ContentData: '@base64(outputs(\'Create_CDC_SalesOrder_record\'))'
//             }
//             path: '/@{encodeURIComponent(\'eh-omnisync-prod-ne-01\')}/events'
//             queries: {
//               partitionKey: '0'
//             }
//           }
//         }
//         Parse_SalesForce_CDC_JSON_record: {
//           runAfter: {}
//           type: 'ParseJson'
//           inputs: {
//             content: '@triggerBody().data.message'
//             schema: {
//               type: 'object'
//               properties: {
//                 replayId: {
//                   type: 'integer'
//                 }
//                 payload: {
//                   type: 'object'
//                   properties: {
//                     ChangeEventHeader: {
//                       type: 'object'
//                       properties: {
//                         entityName: {
//                           type: 'string'
//                         }
//                         recordIds: {
//                           type: 'array'
//                           items: {
//                             type: 'string'
//                           }
//                         }
//                         changeType: {
//                           type: 'string'
//                         }
//                         changeOrigin: {
//                           type: 'string'
//                         }
//                         transactionKey: {
//                           type: 'string'
//                         }
//                         sequenceNumber: {
//                           type: 'integer'
//                         }
//                         commitTimestamp: {
//                           type: 'integer'
//                         }
//                         commitNumber: {
//                           type: 'integer'
//                         }
//                         commitUser: {
//                           type: 'string'
//                         }
//                         nulledFields: {
//                           type: 'array'
//                         }
//                         diffFields: {
//                           type: 'array'
//                         }
//                         changedFields: {
//                           type: 'array'
//                         }
//                       }
//                     }
//                     OwnerId: {}
//                     Name: {}
//                     CurrencyIsoCode: {}
//                     CreatedDate: {}
//                     CreatedById: {}
//                     LastModifiedDate: {}
//                     LastModifiedById: {}
//                     Product2Id__c: {}
//                     OrderId__c: {}
//                     OrderItemId__c: {}
//                     OrderItemLineNumber__c: {}
//                   }
//                 }
//               }
//             }
//           }
//         }
//         Create_CDC_SalesOrder_record: {
//           runAfter: {
//             Parse_SalesForce_CDC_JSON_record: [
//               'Succeeded'
//             ]
//           }
//           type: 'Compose'
//           inputs: {
//             Operation: 'Delete'
//             Entity: 'SalesOrders'
//             Values: '{ "SalesForceId": "@{body(\'Parse_SalesForce_CDC_JSON_record\')?[\'payload\']?[\'OrderItemId__c\']}"}'
//             CreatedDate: '@utcNow()'
//             UpdatedDate: '@utcNow()'
//           }
//         }
//       }
//       outputs: {}
//     }
//     parameters: {
//       '$connections': {
//         value: {
//           eventhubs: {
//             id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/eventhubs'
//             connectionId: connections_eventhubs_id
//             connectionName: 'eventhubs'
//           }
//         }
//       }
//     }
//   }
// }

// output wf_sf_fabric_omnisync_orderdetails_delete_callbackurl string = listCallbackURL('${wf_sf_fabric_omnisync_orderdetails_delete.id}/triggers/When_a_HTTP_request_is_received', '2019-05-01').value
