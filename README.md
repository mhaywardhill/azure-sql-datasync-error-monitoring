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

## 🏛️ Architecture

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

### 1️⃣ Deploy Infrastructure

```bash
cd infra

# Login to Azure
az login --tenant <tenant-id> --use-device-code

# Deploy (default region: uksouth)
./deploy.sh rg-datasync-demo uksouth "YourSecureP@ssw0rd!"
```

### 2️⃣ Create Sample Tables

Run the sample schema on both databases:

```bash
# Hub Database
az sql db execute \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --file sample-schema.sql

# Member Database
az sql db execute \
    --resource-group rg-datasync-demo \
    --server <member-server-name> \
    --database MemberDatabase \
    --file sample-schema.sql
```

> **Tip:** You can also use [Azure Data Studio](https://azure.microsoft.com/products/data-studio/) or SSMS to run the script.

### 3️⃣ Configure Sync Schema

```bash
./configure-sync-schema.sh rg-datasync-demo <hub-server-name>
```

### Trigger Synchronization

```bash
az sql sync-group trigger-sync \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --name SampleSyncGroup
```

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
│   ├── configure-sync-schema.sh # Sync schema configuration
│   └── cleanup.sh              # Resource cleanup script
├── LICENSE
└── README.md
```

---

## Configuration

### Deployment Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `sqlAdminLogin` | `sqladmin` | SQL Server admin username |
| `sqlAdminPassword` | — | SQL Server admin password *(required)* |
| `namePrefix` | `datasync` | Prefix for resource names |
| `databaseSkuName` | `Basic` | Database SKU (`Basic`, `Standard`, `Premium`) |
| `syncIntervalInSeconds` | `300` | Sync interval (`-1` for manual only) |
| `conflictResolutionPolicy` | `HubWin` | Conflict resolution (`HubWin` or `MemberWin`) |

---

## Monitoring

### Check Sync Status

```bash
az sql sync-group show \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --name SampleSyncGroup \
    --query '{state: syncState, interval: interval}'
```

### View Sync Logs

```bash
az sql sync-group list-logs \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --name SampleSyncGroup \
    --start-time "2024-01-01T00:00:00Z" \
    --end-time "2024-12-31T23:59:59Z" \
    --type All
```

### List Sync Members

```bash
az sql sync-member list \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --sync-group-name SampleSyncGroup
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
az sql sync-member refresh-schema \
    --resource-group rg-datasync-demo \
    --server <hub-server-name> \
    --database HubDatabase \
    --sync-group-name SampleSyncGroup \
    --name MemberDatabase
```

---

## 📚 Resources

- [Azure SQL Data Sync Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/sql-data-sync-data-sql-server-sql-database)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/sql/sync-group)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.