#!/bin/bash

# Azure SQL Data Sync Infrastructure Deployment Script
# Usage: ./deploy.sh <resource-group-name> <location> <sql-admin-password>

set -e

RESOURCE_GROUP=${1:-"rg-datasync-demo"}
LOCATION=${2:-"uksouth"}
SQL_ADMIN_PASSWORD=${3:-""}

if [ -z "$SQL_ADMIN_PASSWORD" ]; then
    echo "Error: SQL Admin Password is required"
    echo "Usage: ./deploy.sh <resource-group-name> <location> <sql-admin-password>"
    echo "Example: ./deploy.sh rg-datasync-demo eastus 'MySecureP@ssw0rd!'"
    exit 1
fi

echo "=== Azure SQL Data Sync Deployment ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo ""

# Check if logged in to Azure
echo "Checking Azure CLI login status..."
az account show > /dev/null 2>&1 || { echo "Please login to Azure using 'az login'"; exit 1; }

# Create resource group if it doesn't exist
echo "Creating resource group if it doesn't exist..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Deploy the Bicep template
echo "Deploying Azure SQL Data Sync infrastructure..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters sqlAdminLogin='sqladmin' \
    --parameters sqlAdminPassword="$SQL_ADMIN_PASSWORD" \
    --query 'properties.outputs' \
    --output json)

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Deployment Outputs:"
echo "$DEPLOYMENT_OUTPUT" | jq .

# Extract values for display
HUB_SERVER=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.hubServerFqdn.value')
MEMBER_SERVER=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.memberServerFqdn.value')
HUB_SERVER_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.hubServerName.value')
MEMBER_SERVER_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.memberServerName.value')
HUB_DB=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.hubDatabaseName.value')
MEMBER_DB=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.memberDatabaseName.value')
SYNC_GROUP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.syncGroupName.value')

echo ""
echo "=== Connection Information ==="
echo "Hub Server: $HUB_SERVER"
echo "Hub Database: $HUB_DB"
echo "Member Server: $MEMBER_SERVER"
echo "Member Database: $MEMBER_DB"
echo "Sync Group: $SYNC_GROUP"
echo ""
echo "SQL Admin: sqladmin"
echo ""
echo "Connection String (Hub):"
echo "Server=$HUB_SERVER;Database=$HUB_DB;User Id=sqladmin;Password=<your-password>;Encrypt=True;TrustServerCertificate=False;"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Add your client IP to the firewall rules:"
echo "   MY_IP=\$(curl -s ifconfig.me)"
echo "   az sql server firewall-rule create --resource-group $RESOURCE_GROUP --server $HUB_SERVER_NAME --name AllowMyIP --start-ip-address \$MY_IP --end-ip-address \$MY_IP"
echo "   az sql server firewall-rule create --resource-group $RESOURCE_GROUP --server $MEMBER_SERVER_NAME --name AllowMyIP --start-ip-address \$MY_IP --end-ip-address \$MY_IP"
echo ""
echo "2. Create sample tables by running sample-schema.sql on both databases"
echo ""
echo "3. Configure sync schema using configure-sync-schema.sh"
echo ""
