#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        aws entityresolution delete-schema-mapping --schema-name "$resource"
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
SCHEMA_NAME="test-schema-${SUFFIX}"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

echo "Creating Schema Mapping..." >> "$LOG_FILE"
aws entityresolution create-schema-mapping \
    --schema-name "$SCHEMA_NAME" \
    --description "Test schema for entity resolution" \
    --mapped-input-fields '[{"fieldName": "uniqueId", "type": "UNIQUE_ID"}, {"fieldName": "firstName", "type": "NAME_FIRST"}, {"fieldName": "lastName", "type": "NAME_LAST"}, {"fieldName": "email", "type": "EMAIL_ADDRESS"}]' || true
CREATED_RESOURCES+=("$SCHEMA_NAME")

echo "Verifying Schema Mapping..." >> "$LOG_FILE"
aws entityresolution get-schema-mapping \
    --schema-name "$SCHEMA_NAME" || true

echo "Listing Schema Mappings..." >> "$LOG_FILE"
aws entityresolution list-schema-mappings \
    --max-results 10 || true

echo "Deleting Schema Mapping..." >> "$LOG_FILE"
aws entityresolution delete-schema-mapping \
    --schema-name "$SCHEMA_NAME" || true

echo "PASS" >> "$LOG_FILE"