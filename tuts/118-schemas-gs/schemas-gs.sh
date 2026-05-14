#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws schemas delete-registry --registry-name "$resource" > /dev/null || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
REGISTRY_NAME="test-registry-${SUFFIX}"
SCHEMA_NAME="test-schema-${SUFFIX}"
CONTENT="{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"integer\"}}}"
SCHEMA_TYPE="JSONSchemaDraft4"

echo "Step 1: Creating Registry..." 
aws schemas create-registry --registry-name "$REGISTRY_NAME" --description "Test Registry" > /dev/null
CREATED_RESOURCES+=("$REGISTRY_NAME")
echo "Registry Created" 

sleep 2

echo "Step 2: Describing Registry..." 
aws schemas describe-registry --registry-name "$REGISTRY_NAME" > /dev/null
echo "Registry Described" 

echo "Step 3: Creating Schema..." 
aws schemas create-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" --content "$CONTENT" --description "Test Schema" --type "$SCHEMA_TYPE" > /dev/null
echo "Schema Created" 

sleep 2

echo "Step 4: Describing Schema..." 
aws schemas describe-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" > /dev/null
echo "Schema Described" 

echo "Step 5: Listing Schemas..." 
aws schemas list-schemas --registry-name "$REGISTRY_NAME" > /dev/null
echo "Schemas Listed" 

echo "Step 6: Deleting Schema..." 
aws schemas delete-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" > /dev/null
echo "Schema Deleted" 

sleep 2

echo "Step 7: Deleting Registry..." 
aws schemas delete-registry --registry-name "$REGISTRY_NAME" > /dev/null
echo "Registry Deleted" 

echo "PASS" 