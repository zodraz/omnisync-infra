using './main.bicep'

param geoapiSecret = readEnvironmentVariable('geoapiSecret','')
param env = readEnvironmentVariable('env','prod')
param location_abbreviation = readEnvironmentVariable('location_abbreviation','ne')
param location  = readEnvironmentVariable('location','northeurope')
param resource_number = readEnvironmentVariable('resource_number','01')
param kv_resource_number = readEnvironmentVariable('kv_resource_number','10')
param st_resource_number = readEnvironmentVariable('st_resource_number','03')
