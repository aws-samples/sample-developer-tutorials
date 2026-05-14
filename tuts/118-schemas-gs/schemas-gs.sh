#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
REGISTRY_NAME="test-registry-${SUFFIX}"
SCHEMA_NAME="test-schema-${SUFFIX}"
CONTENT="{\"type\":\"object\",\"properties\":{\"id\":{\"type\":\"integer\"}}}"
SCHEMA_TYPE="JSONSchemaDraft4"

echo "Creating Registry..."
aws schemas create-registry --registry-name "$REGISTRY_NAME" --description "Test Registry" > /dev/null
echo "Registry Created"

sleep 2

echo "Describing Registry..."
aws schemas describe-registry --registry-name "$REGISTRY_NAME" > /dev/null
echo "Registry Described"

echo "Creating Schema..."
aws schemas create-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" --content "$CONTENT" --description "Test Schema" --type "$SCHEMA_TYPE" > /dev/null
echo "Schema Created"

sleep 2

echo "Describing Schema..."
aws schemas describe-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" > /dev/null
echo "Schema Described"

echo "Listing Schemas..."
aws schemas list-schemas --registry-name "$REGISTRY_NAME" > /dev/null
echo "Schemas Listed"

echo "Deleting Schema..."
aws schemas delete-schema --registry-name "$REGISTRY_NAME" --schema-name "$SCHEMA_NAME" > /dev/null
echo "Schema Deleted"

sleep 2

echo "Deleting Registry..."
aws schemas delete-registry --registry-name "$REGISTRY_NAME" > /dev/null
echo "Registry Deleted"

echo "PASS"