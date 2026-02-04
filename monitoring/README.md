# Data Sync Error Monitoring

This folder contains scripts and documentation for monitoring Azure SQL Data Sync errors using PowerShell.

## Prerequisites

- [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps) (Az.Sql)
- Azure subscription with access to the SQL Data Sync resources

```powershell
# Install Azure PowerShell module if not already installed
Install-Module -Name Az -Repository PSGallery -Force

# Import the SQL module
Import-Module Az.Sql
```

## Authentication

```powershell
# Login to Azure
Connect-AzAccount -TenantId "<tenant-id>"

# Set subscription context
Set-AzContext -SubscriptionId "<subscription-id>"
```

## Monitoring Commands

### Get Sync Group Status

```powershell
# Define variables
$resourceGroup = "rg-datasync-demo"
$serverName = "<hub-server-name>"
$databaseName = "HubDatabase"
$syncGroupName = "SampleSyncGroup"

# Get sync group details
Get-AzSqlSyncGroup -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName | Format-List
```

> **Note:** The `LastSyncTime` property from `Get-AzSqlSyncGroup` may show `1/1/0001` even when syncs are completing successfully. Use `Get-AzSqlSyncGroupLog` to get accurate sync timestamps.

### Get Sync Group Logs (Recommended for Monitoring)

Use `Get-AzSqlSyncGroupLog` to monitor sync activity. This provides accurate timestamps and detailed sync status.

```powershell
# Get sync logs for the last 24 hours
$startTime = (Get-Date).AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

Get-AzSqlSyncGroupLog -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName `
    -StartTime $startTime `
    -EndTime $endTime
```

### Get Last Successful Sync Time

```powershell
# Get the most recent successful sync timestamp
$startTime = (Get-Date).AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

Get-AzSqlSyncGroupLog -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName `
    -StartTime $startTime `
    -EndTime $endTime |
    Where-Object { $_.Details -like "*completed*" -or $_.Type -eq "Success" } |
    Select-Object -First 1 Timestamp, Type, Details
```

### Filter for Errors Only

```powershell
# Get only error logs
Get-AzSqlSyncGroupLog -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName `
    -StartTime $startTime `
    -EndTime $endTime | 
    Where-Object { $_.Type -eq "Error" }
```

### Get Sync Members

```powershell
# List all sync members in the group
Get-AzSqlSyncMember -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName
```

### Get Sync Agent (for on-premises databases)

```powershell
# Get sync agents registered with the server
Get-AzSqlSyncAgent -ResourceGroupName $resourceGroup `
    -ServerName $serverName
```

### Trigger Manual Sync

```powershell
# Start a manual sync
Start-AzSqlSyncGroupSync -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName
```

### Stop Running Sync

```powershell
# Stop a running sync operation
Stop-AzSqlSyncGroupSync -ResourceGroupName $resourceGroup `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -SyncGroupName $syncGroupName
```

## Automated Error Monitoring Script

Create a PowerShell script to check for sync errors and send alerts:

```powershell
# Monitor-DataSyncErrors.ps1
param(
    [string]$ResourceGroup = "rg-datasync-demo",
    [string]$ServerName = "<hub-server-name>",
    [string]$DatabaseName = "HubDatabase",
    [string]$SyncGroupName = "SampleSyncGroup",
    [int]$CheckIntervalMinutes = 15
)

# Get logs from the last check interval
$startTime = (Get-Date).AddMinutes(-$CheckIntervalMinutes).ToString("yyyy-MM-ddTHH:mm:ssZ")
$endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")

$errors = Get-AzSqlSyncGroupLog -ResourceGroupName $ResourceGroup `
    -ServerName $ServerName `
    -DatabaseName $DatabaseName `
    -SyncGroupName $SyncGroupName `
    -StartTime $startTime `
    -EndTime $endTime | 
    Where-Object { $_.Type -eq "Error" }

if ($errors) {
    Write-Host "=== DATA SYNC ERRORS DETECTED ===" -ForegroundColor Red
    $errors | ForEach-Object {
        Write-Host "Time: $($_.Timestamp)" -ForegroundColor Yellow
        Write-Host "Source: $($_.Source)"
        Write-Host "Details: $($_.Details)"
        Write-Host "---"
    }
    
    # Optional: Send email alert
    # Send-MailMessage -To "admin@company.com" -Subject "Data Sync Errors Detected" -Body ($errors | Out-String)
    
    # Optional: Write to Event Log
    # Write-EventLog -LogName Application -Source "DataSyncMonitor" -EventId 1001 -EntryType Error -Message ($errors | Out-String)
    
    exit 1
} else {
    Write-Host "No sync errors in the last $CheckIntervalMinutes minutes" -ForegroundColor Green
    exit 0
}
```

## Sync Status Values

| Status | Description |
|--------|-------------|
| `Good` | Sync is running normally |
| `Warning` | Sync has warnings but is operational |
| `Error` | Sync has errors and may not be working |
| `NotReady` | Sync group is not configured or provisioned |
| `Progressing` | Sync is currently in progress |

## Common Error Types

| Error | Cause | Resolution |
|-------|-------|------------|
| **Schema mismatch** | Tables/columns differ between hub and member | Ensure identical schema on all databases |
| **Primary key conflict** | Same key inserted on multiple databases | Configure conflict resolution policy |
| **Connection failure** | Cannot connect to member database | Check firewall rules and credentials |
| **Timeout** | Sync operation timed out | Check network latency, reduce batch size |
| **Data truncation** | Data exceeds column size | Fix data or increase column size |

## Generate Test Errors

Use the `generate-sync-errors.sql` script to create test error scenarios:

```powershell
# Connect to hub database using Invoke-Sqlcmd
Invoke-Sqlcmd -ServerInstance "<hub-server>.database.windows.net" `
    -Database "HubDatabase" `
    -Username "<admin-user>" `
    -Password "<password>" `
    -InputFile ".\generate-sync-errors.sql"
```

## Resources

- [Az.Sql PowerShell Reference](https://docs.microsoft.com/en-us/powershell/module/az.sql/)
- [Data Sync Troubleshooting](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-troubleshoot)
- [Monitor Data Sync with Log Analytics](https://docs.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-monitor-oms)
