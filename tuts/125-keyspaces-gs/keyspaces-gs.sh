#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
KS_NAME="ks_${SUFFIX}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws keyspaces delete-keyspace --keyspace-name "$resource" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Creating Keyspace..." >> "$LOG_FILE"
aws keyspaces create-keyspace --keyspace-name "$KS_NAME" --query 'Path' --output text >> "$LOG_FILE"
sleep 5
echo "Keyspace created" >> "$LOG_FILE"
CREATED_RESOURCES+=("$KS_NAME")

echo "Creating Table..." >> "$LOG_FILE"
aws keyspaces create-table --keyspace-name "$KS_NAME" --table-name "users" --schema-definition '{"allColumns":[{"name":"id","type":"text"},{"name":"name","type":"text"}],"partitionKeys":[{"name":"id"}]}' --query 'Path' --output text >> "$LOG_FILE"
sleep 10
echo "Table created" >> "$LOG_FILE"

echo "Verifying Keyspace and Table..." >> "$LOG_FILE"
aws keyspaces get-keyspace --keyspace-name "$KS_NAME" --query 'Path' --output text >> "$LOG_FILE"
aws keyspaces get-table --keyspace-name "$KS_NAME" --table-name "users" --query 'Path' --output text >> "$LOG_FILE"
echo "Keyspace and Table verified" >> "$LOG_FILE"

echo "Waiting for table to be fully active before deletion..." >> "$LOG_FILE"
sleep 30

echo "Deleting Table..." >> "$LOG_FILE"
aws keyspaces delete-table --keyspace-name "$KS_NAME" --table-name "users" || true
sleep 10
echo "Table deleted" >> "$LOG_FILE"

echo "Waiting before attempting to delete Keyspace..." >> "$LOG_FILE"
sleep 30

echo "Deleting Keyspace..." >> "$LOG_FILE"
aws keyspaces delete-keyspace --keyspace-name "$KS_NAME" || true
echo "Keyspace deleted" >> "$LOG_FILE"

echo "PASS" >> "$LOG_FILE"