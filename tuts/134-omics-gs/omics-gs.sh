#!/bin/bash
set -e

REGION_NAME='us-east-1'
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for res in "${CREATED_RESOURCES[@]}"; do
        aws omics delete-sequence-store --id "$res" || true
    done
    rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
NAME="test-sequence-store-${SUFFIX}"
DESCRIPTION="Test sequence store for demonstration"
CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

echo "Step 1: Creating sequence store"
SEQUENCE_STORE_ID=$(aws omics create-sequence-store \
    --name "${NAME}" \
    --description "${DESCRIPTION}" \
    --client-token "${CLIENT_TOKEN}" \
    --query 'id' \
    --output text)
CREATED_RESOURCES+=("${SEQUENCE_STORE_ID}")
echo "Sequence store created with ID: ${SEQUENCE_STORE_ID}"

echo "Step 2: Verifying sequence store creation"
GET_RESPONSE=$(aws omics get-sequence-store \
    --id "${SEQUENCE_STORE_ID}" \
    --query 'name' \
    --output text)
echo "Retrieved sequence store: ${GET_RESPONSE}"

echo "Step 3: Listing sequence stores"
LIST_RESPONSE=$(aws omics list-sequence-stores \
    --max-results 10)
echo "List of sequence stores: ${LIST_RESPONSE}"

echo "Step 4: Deleting sequence store"
aws omics delete-sequence-store \
    --id "${SEQUENCE_STORE_ID}" || true

echo "Sequence store deleted"
echo "PASS"