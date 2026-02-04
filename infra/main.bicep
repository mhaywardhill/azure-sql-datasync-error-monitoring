@description('The location for all resources')
param location string = resourceGroup().location

@description('The administrator login for the SQL servers')
param sqlAdminLogin string

@secure()
@description('The administrator password for the SQL servers')
param sqlAdminPassword string

@description('The name prefix for resources')
param namePrefix string = 'datasync'

@description('The SKU name for the SQL databases')
param databaseSkuName string = 'Basic'

@description('The sync interval in seconds (-1 for manual sync only)')
param syncIntervalInSeconds int = 300

@description('Conflict resolution policy: HubWin or MemberWin')
@allowed([
  'HubWin'
  'MemberWin'
])
param conflictResolutionPolicy string = 'HubWin'

var uniqueSuffix = uniqueString(resourceGroup().id)
var hubServerName = '${namePrefix}-hub-${uniqueSuffix}'
var memberServerName = '${namePrefix}-member-${uniqueSuffix}'
var hubDatabaseName = 'HubDatabase'
var memberDatabaseName = 'MemberDatabase'
var syncDatabaseName = 'SyncMetadataDatabase'
var syncGroupName = 'SampleSyncGroup'

// Hub SQL Server
resource hubServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: hubServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Member SQL Server
resource memberServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: memberServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

// Firewall rule to allow Azure services on Hub Server
resource hubServerFirewallAzure 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: hubServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Firewall rule to allow Azure services on Member Server
resource memberServerFirewallAzure 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = {
  parent: memberServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Hub Database
resource hubDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: hubServer
  name: hubDatabaseName
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

// Member Database
resource memberDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: memberServer
  name: memberDatabaseName
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

// Sync Metadata Database (on Hub Server)
resource syncDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: hubServer
  name: syncDatabaseName
  location: location
  sku: {
    name: databaseSkuName
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
}

// Sync Group
resource syncGroup 'Microsoft.Sql/servers/databases/syncGroups@2023-05-01-preview' = {
  parent: hubDatabase
  name: syncGroupName
  properties: {
    interval: syncIntervalInSeconds
    conflictResolutionPolicy: conflictResolutionPolicy
    syncDatabaseId: syncDatabase.id
    hubDatabaseUserName: sqlAdminLogin
    hubDatabasePassword: sqlAdminPassword
    usePrivateLinkConnection: false
  }
}

// Sync Member
resource syncMember 'Microsoft.Sql/servers/databases/syncGroups/syncMembers@2023-05-01-preview' = {
  parent: syncGroup
  name: 'MemberDatabase'
  properties: {
    databaseType: 'AzureSqlDatabase'
    serverName: memberServer.properties.fullyQualifiedDomainName
    databaseName: memberDatabaseName
    userName: sqlAdminLogin
    password: sqlAdminPassword
    syncDirection: 'Bidirectional'
    usePrivateLinkConnection: false
  }
}

// Outputs
output hubServerFqdn string = hubServer.properties.fullyQualifiedDomainName
output memberServerFqdn string = memberServer.properties.fullyQualifiedDomainName
output hubDatabaseName string = hubDatabaseName
output memberDatabaseName string = memberDatabaseName
output syncGroupName string = syncGroupName
output hubServerName string = hubServerName
output memberServerName string = memberServerName
