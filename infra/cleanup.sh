#!/bin/bash

# Cleanup script for SQL Data Sync demo resources
# WARNING: This will delete all resources in the specified resource group

set -e

RESOURCE_GROUP=${1:-"rg-datasync-demo"}

echo "=== SQL Data Sync Resource Cleanup ==="
echo "WARNING: This will delete all resources in resource group: $RESOURCE_GROUP"
echo ""
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting resource group: $RESOURCE_GROUP"
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    echo "Deletion initiated. Resources will be removed in the background."
else
    echo "Cleanup cancelled."
fi
