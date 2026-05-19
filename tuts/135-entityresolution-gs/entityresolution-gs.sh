#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)

cleanup() {
    echo "Cleaning up temporary directory: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

echo "Creating schema mapping..."
SCHEMA_NAME="test-schema-$SUFFIX"
MAPPED_INPUT_FIELDS='[{"fieldName":"id","type":"UNIQUE_ID"},{"fieldName":"name","type":"NAME"}]'
aws entityresolution create-schema-mapping --schema-name "$SCHEMA_NAME" --mapped-input-fields "$MAPPED_INPUT_FIELDS"

echo "Retrieving schema mapping..."
aws entityresolution get-schema-mapping --schema-name "$SCHEMA_NAME"

echo "Listing all schema mappings..."
aws entityresolution list-schema-mappings

echo "Deleting schema mapping..."
aws entityresolution delete-schema-mapping --schema-name "$SCHEMA_NAME"

echo "PASS"
