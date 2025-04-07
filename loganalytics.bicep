param env string = 'prod'
param location_abbreviation string ='ne'
param resource_number string='01'
param suffix string = '${env}-${location_abbreviation}-${resource_number}'
param location string ='northeurope'
param workspaces_log_omnisync_name string = 'log-omnisync-${suffix}'
param sol_logicapps_omnisync_name string = 'sol-logicapps-omnisync-${suffix}'

resource workspaces_log_omnisync 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaces_log_omnisync_name
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: json('0.023')
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource sol_logicapps_omnisync 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: sol_logicapps_omnisync_name
  location: location
  plan: {
    name: sol_logicapps_omnisync_name
    promotionCode: ''
    product: 'OMSGallery/LogicAppsManagement'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: workspaces_log_omnisync.id
    containedResources: [
      '${workspaces_log_omnisync.id}/views/${sol_logicapps_omnisync_name}'
    ]
  }
}
