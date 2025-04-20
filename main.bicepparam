using './main.bicep'

param geo_api_secret = readEnvironmentVariable('geoapiSecret','')
param env = readEnvironmentVariable('env','prod')
param location_abbreviation = readEnvironmentVariable('location_abbreviation','ne')
param location  = readEnvironmentVariable('location','northeurope')
param resource_number = readEnvironmentVariable('resource_number','01')
param kv_resource_number = readEnvironmentVariable('kv_resource_number','12')
param st_resource_number = readEnvironmentVariable('st_resource_number','04')
