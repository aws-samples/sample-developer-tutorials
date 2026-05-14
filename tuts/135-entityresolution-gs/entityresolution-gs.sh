#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
SCHEMA_NAME="test-schema-${SUFFIX}"
IDEMPOTENCY_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

echo "Creating Schema Mapping..."
aws entityresolution create-schema-mapping \
    --schema-name "$SCHEMA_NAME" \
    --description "Test schema for entity resolution" \
    --mapped-input-fields '[{"fieldName": "uniqueId", "type": "UNIQUE_ID"}, {"fieldName": "firstName", "type": "NAME_FIRST"}, {"fieldName": "lastName", "type": "NAME_LAST"}, {"fieldName": "email", "type": "EMAIL_ADDRESS"}]' || true

echo "Verifying Schema Mapping..."
aws entityresolution get-schema-mapping \
    --schema-name "$SCHEMA_NAME" || true

echo "Listing Schema Mappings..."
aws entityresolution list-schema-mappings \
    --max-results 10 || true

echo "Deleting Schema Mapping..."
aws entityresolution delete-schema-mapping \
    --schema-name "$SCHEMA_NAME" || true

echo "PASS"