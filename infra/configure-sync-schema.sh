#!/bin/bash

# Configure Sync Schema for SQL Data Sync
# This script adds tables to the sync group schema

set -e

RESOURCE_GROUP=${1:-"rg-datasync-demo"}
HUB_SERVER_NAME=${2:-""}
SYNC_GROUP_NAME=${3:-"SampleSyncGroup"}
HUB_DATABASE_NAME=${4:-"HubDatabase"}

if [ -z "$HUB_SERVER_NAME" ]; then
    echo "Usage: ./configure-sync-schema.sh <resource-group> <hub-server-name> [sync-group-name] [hub-database-name]"
    echo "Example: ./configure-sync-schema.sh rg-datasync-demo datasync-hub-abc123"
    exit 1
fi

echo "=== Configuring Sync Schema ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Hub Server: $HUB_SERVER_NAME"
echo "Hub Database: $HUB_DATABASE_NAME"
echo "Sync Group: $SYNC_GROUP_NAME"
echo ""

# Define the sync schema JSON
SYNC_SCHEMA=$(cat <<EOF
{
  "tables": [
    {
      "columns": [
        { "dataSize": "0", "dataType": "int", "quotedName": "[CustomerId]" },
        { "dataSize": "50", "dataType": "nvarchar", "quotedName": "[FirstName]" },
        { "dataSize": "50", "dataType": "nvarchar", "quotedName": "[LastName]" },
        { "dataSize": "100", "dataType": "nvarchar", "quotedName": "[Email]" },
        { "dataSize": "20", "dataType": "nvarchar", "quotedName": "[Phone]" },
        { "dataSize": "50", "dataType": "nvarchar", "quotedName": "[City]" },
        { "dataSize": "50", "dataType": "nvarchar", "quotedName": "[Country]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[CreatedDate]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[ModifiedDate]" }
      ],
      "quotedName": "[dbo].[Customers]"
    },
    {
      "columns": [
        { "dataSize": "0", "dataType": "int", "quotedName": "[ProductId]" },
        { "dataSize": "100", "dataType": "nvarchar", "quotedName": "[ProductName]" },
        { "dataSize": "50", "dataType": "nvarchar", "quotedName": "[Category]" },
        { "dataSize": "0", "dataType": "decimal", "quotedName": "[Price]" },
        { "dataSize": "0", "dataType": "int", "quotedName": "[StockQuantity]" },
        { "dataSize": "0", "dataType": "bit", "quotedName": "[IsActive]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[CreatedDate]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[ModifiedDate]" }
      ],
      "quotedName": "[dbo].[Products]"
    },
    {
      "columns": [
        { "dataSize": "0", "dataType": "int", "quotedName": "[OrderId]" },
        { "dataSize": "0", "dataType": "int", "quotedName": "[CustomerId]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[OrderDate]" },
        { "dataSize": "0", "dataType": "decimal", "quotedName": "[TotalAmount]" },
        { "dataSize": "20", "dataType": "nvarchar", "quotedName": "[Status]" },
        { "dataSize": "200", "dataType": "nvarchar", "quotedName": "[ShippingAddress]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[CreatedDate]" },
        { "dataSize": "8", "dataType": "datetime2", "quotedName": "[ModifiedDate]" }
      ],
      "quotedName": "[dbo].[Orders]"
    }
  ],
  "masterSyncMemberName": null
}
EOF
)

echo "Refreshing hub schema..."
az sql sync-group refresh-hub-schema \
    --resource-group "$RESOURCE_GROUP" \
    --server "$HUB_SERVER_NAME" \
    --database "$HUB_DATABASE_NAME" \
    --name "$SYNC_GROUP_NAME"

echo "Waiting for schema refresh to complete..."
sleep 30

echo "Updating sync schema..."
echo "$SYNC_SCHEMA" > /tmp/sync-schema.json

az sql sync-group update \
    --resource-group "$RESOURCE_GROUP" \
    --server "$HUB_SERVER_NAME" \
    --database "$HUB_DATABASE_NAME" \
    --name "$SYNC_GROUP_NAME" \
    --schema @/tmp/sync-schema.json

rm /tmp/sync-schema.json

echo ""
echo "=== Sync Schema Configuration Complete ==="
echo ""
echo "To trigger a manual sync:"
echo "az sql sync-group trigger-sync --resource-group $RESOURCE_GROUP --server $HUB_SERVER_NAME --database $HUB_DATABASE_NAME --name $SYNC_GROUP_NAME"
echo ""
echo "To check sync status:"
echo "az sql sync-group show --resource-group $RESOURCE_GROUP --server $HUB_SERVER_NAME --database $HUB_DATABASE_NAME --name $SYNC_GROUP_NAME --query 'syncState'"
echo ""
