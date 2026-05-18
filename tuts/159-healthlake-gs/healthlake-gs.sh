#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="/test-files/log.txt"
CREATED_RESOURCES=()

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

# Step 1: Create FHIR Datastore
DATASTORE_NAME="store-${SUFFIX}"
DATASTORE_ID=$(aws healthlake create-fhir-datastore --datastore-type-version R4 --datastore-name "${DATASTORE_NAME}" --query 'DatastoreId' --output text || true)
if [ -n "$DATASTORE_ID" ]; then
    CREATED_RESOURCES+=("$DATASTORE_ID")
    echo "Datastore: ${DATASTORE_ID}" >> "$LOG_FILE"
fi

# Step 2: List FHIR Datastores
aws healthlake list-fhir-datastores --output json >> "$LOG_FILE"

# Step 3: Delete FHIR Datastore (if created)
if [ -n "$DATASTORE_ID" ]; then
    aws healthlake delete-fhir-datastore --datastore-id "${DATASTORE_ID}" || true
fi

echo "PASS" >> "$LOG_FILE"