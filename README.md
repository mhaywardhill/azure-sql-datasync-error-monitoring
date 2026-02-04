# Azure SQL Data Sync Error Monitoring

[![Azure](https://img.shields.io/badge/Azure-SQL%20Data%20Sync-0078D4?logo=microsoft-azure&logoColor=white)](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-data-sql-server-sql-database)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-orange?logo=azure-devops)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Infrastructure as Code (IaC) solution for deploying and monitoring Azure SQL Database Data Sync environments.

---

## Overview

Azure SQL Data Sync is a service that synchronizes data across multiple databases (Azure SQL Database and/or on-premises SQL Server). This project provides:

| Component | Description |
|-----------|-------------|
| **Bicep Templates** | Automated infrastructure deployment |
| **Sample Schema** | Ready-to-use tables for testing synchronization |
| **Management Scripts** | Configuration and operational tooling |

---

## Architecture

```
┌───────────────────────┐              ┌───────────────────────┐
│      Hub Server       │              │    Member Server      │
│  ┌─────────────────┐  │              │  ┌─────────────────┐  │
│  │   Hub Database  │◄─┼──────────────┼─►│  Member Database│  │
│  └─────────────────┘  │  Sync Group  │  └─────────────────┘  │
│  ┌─────────────────┐  │              │                       │
│  │  Sync Metadata  │  │              │                       │
│  └─────────────────┘  │              │                       │
└───────────────────────┘              └───────────────────────┘
```

### Infrastructure Components

| Resource | Description |
|----------|-------------|
| **Hub SQL Server** | Hosts the hub database and sync metadata |
| **Member SQL Server** | Hosts the member database |
| **Hub Database** | Central database in the sync topology |
| **Member Database** | Database synchronized with the hub |
| **Sync Metadata Database** | Stores sync group configuration and state |
| **Sync Group** | Defines the sync topology and schedule |
| **Sync Member** | Connects member database to the sync group |

---

## Quick Start

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.20+ with Bicep)
- Azure subscription with Contributor access
- Bash shell (Linux, macOS, WSL, or GitHub Codespaces)
- [SQL Server Management Studio](https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms) or [Azure Data Studio](https://azure.microsoft.com/products/data-studio/)

### 1️⃣ Deploy Infrastructure

```bash
cd infra

# Login to Azure
az login --tenant <tenant-id> --use-device-code

# Deploy (default region: uksouth)
./deploy.sh rg-datasync-demo uksouth "YourSecureP@ssw0rd!"
```

### 2️⃣ Add Firewall Rules

Add your client IP to access the databases:

```bash
$MY_IP =$(Invoke-RestMethod https://api.ipify.org)
az sql server firewall-rule create --resource-group rg-datasync-demo --server <hub-server-name> --name AllowMyIP --start-ip-address $MY_IP --end-ip-address $MY_IP
az sql server firewall-rule create --resource-group rg-datasync-demo --server <member-server-name> --name AllowMyIP --start-ip-address $MY_IP --end-ip-address $MY_IP
```

### 3️⃣ Create Sample Tables

Connect to **both** databases using SSMS or Azure Data Studio and run `sample-schema.sql`:

- **Hub Server:** `<hub-server-name>.database.windows.net` → `HubDatabase`
- **Member Server:** `<member-server-name>.database.windows.net` → `MemberDatabase`

### 4️⃣ Configure Sync Schema (Azure Portal)

The sync schema must be configured via Azure Portal:

1. Navigate to **Azure Portal** → **rg-datasync-demo** → **HubDatabase**
2. Select **SQL Data Sync** under Settings
3. Click on **SampleSyncGroup**
4. Go to the **Tables** tab
5. Select the tables to sync: `Customers`, `Products`, `Orders`
6. Click **Save** and wait for provisioning


---

## Project Structure

```
.
├── .devcontainer/
│   └── devcontainer.json       # GitHub Codespaces configuration
├── infra/
│   ├── main.bicep              # Main Bicep template
│   ├── main.bicepparam         # Bicep parameters file
│   ├── deploy.sh               # Deployment script
│   ├── sample-schema.sql       # Sample database schema
│   └── cleanup.sh              # Resource cleanup script
├── monitoring/
│   ├── README.md               # PowerShell monitoring guide
│   └── generate-sync-errors.sql # Script to generate test errors
├── LICENSE
└── README.md
```

---

## Configuration

### Deployment Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `sqlAdminPassword` | — | SQL Server admin password *(required)* |
| `namePrefix` | `datasync` | Prefix for resource names |
| `databaseSkuName` | `Basic` | Database SKU (`Basic`, `Standard`, `Premium`) |
| `syncIntervalInSeconds` | `300` | Sync interval (`-1` for manual only) |
| `conflictResolutionPolicy` | `HubWin` | Conflict resolution (`HubWin` or `MemberWin`) |

> **Note:** The SQL admin username is auto-generated as `admin` + 8 random characters (e.g., `adminxyz12abc`) and displayed in the deployment output.

---

## Monitoring

> **Note:** The `az sql sync-group` commands have been deprecated. Use `az rest` with the Azure REST API instead.

### Check Sync Status

```bash
# Set variables
$SUBSCRIPTION_ID=$(az account show --query id -o tsv)
$RG="rg-datasync-demo"
$SERVER="<hub-server-name>"
$DB="HubDatabase"
$SYNC_GROUP="SampleSyncGroup"

# Get sync group status
az rest --method GET \
    --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SERVER}/databases/${DB}/syncGroups/${SYNC_GROUP}?api-version=2023-05-01-preview" \
    --query '{state: properties.syncState, interval: properties.interval}'
```

### Trigger Manual Sync

```bash
az rest --method POST \
    --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SERVER}/databases/${DB}/syncGroups/${SYNC_GROUP}/triggerSync?api-version=2023-05-01-preview"
```

### View Sync Logs

```bash
az rest --method GET 
    --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SERVER}/databases/${DB}/syncGroups/${SYNC_GROUP}/logs" `
    --url-parameters startTime=2026-01-01T00:00:00Z endTime=2026-02-04T23:59:59Z type=All api-version=2023-05-01-preview
```

### List Sync Members

```bash
az rest --method GET \
    --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SERVER}/databases/${DB}/syncGroups/${SYNC_GROUP}/syncMembers?api-version=2023-05-01-preview"
```

---

## Cleanup

Remove all deployed resources:

```bash
./cleanup.sh rg-datasync-demo
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Authentication error** | Verify SQL admin credentials are correct |
| **Tables not syncing** | Ensure schema exists on both databases before configuring sync |
| **Firewall errors** | Add your IP to SQL Server firewall rules |
| **Schema refresh fails** | Wait for previous operation to complete, then retry |

### Refresh Member Schema

```bash
az rest --method POST \
    --uri "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SERVER}/databases/${DB}/syncGroups/${SYNC_GROUP}/syncMembers/MemberDatabase/refreshSchema?api-version=2023-05-01-preview"
```

---

## Resources

- [Azure SQL Data Sync Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-data-sql-server-sql-database)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Data Sync REST API Reference](https://learn.microsoft.com/en-us/rest/api/sql/sync-groups)

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.