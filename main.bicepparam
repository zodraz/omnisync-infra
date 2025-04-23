using './main.bicep'

param geo_api_secret = readEnvironmentVariable('geoapiSecret','')
param env = readEnvironmentVariable('env','prod')
param location_abbreviation = readEnvironmentVariable('location_abbreviation','ne')
param location  = readEnvironmentVariable('location','northeurope')
param resource_number = readEnvironmentVariable('resource_number','01')
param kv_resource_number = readEnvironmentVariable('kv_resource_number','12')
param st_resource_number = readEnvironmentVariable('st_resource_number','04')
param d365_organization = readEnvironmentVariable('d365_organization','org58211bdf')
param integration_user = readEnvironmentVariable('integration_user','b4c42b2a-181e-f011-9989-002248a3370c')
param database = readEnvironmentVariable('database','OmniSync_DE_LH_320_Gold_Contoso')
param sql_connection_string = readEnvironmentVariable('sql_connection_string','4zcf2t243paebjgwyd6y3asocu-pkxdk222q4ne5d3at4fcfuha2a.datawarehouse.fabric.microsoft.com')
