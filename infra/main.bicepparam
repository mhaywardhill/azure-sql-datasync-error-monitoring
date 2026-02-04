using './main.bicep'

param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = '' // Set via environment variable or prompt
param namePrefix = 'datasync'
param databaseSkuName = 'Basic'
param syncIntervalInSeconds = 300
param conflictResolutionPolicy = 'HubWin'
