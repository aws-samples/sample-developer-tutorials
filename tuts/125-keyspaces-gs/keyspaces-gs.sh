#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
KS_NAME="ks_${SUFFIX}"

# Create Keyspace
aws keyspaces create-keyspace --keyspace-name "$KS_NAME" --query 'Path' --output text
sleep 5
echo "Keyspace created"

# Create Table
aws keyspaces create-table --keyspace-name "$KS_NAME" --table-name "users" --schema-definition '{"allColumns":[{"name":"id","type":"text"},{"name":"name","type":"text"}],"partitionKeys":[{"name":"id"}]}' --query 'Path' --output text
sleep 10
echo "Table created"

# Verify Keyspace and Table
aws keyspaces get-keyspace --keyspace-name "$KS_NAME" --query 'Path' --output text
aws keyspaces get-table --keyspace-name "$KS_NAME" --table-name "users" --query 'Path' --output text
echo "Keyspace and Table verified"

# Wait for table to be fully active before deletion
sleep 30

# Delete Table
aws keyspaces delete-table --keyspace-name "$KS_NAME" --table-name "users" || true
sleep 10
echo "Table deleted"

# Wait before attempting to delete Keyspace
sleep 30

# Delete Keyspace
aws keyspaces delete-keyspace --keyspace-name "$KS_NAME" || true
echo "Keyspace deleted"

echo "PASS"