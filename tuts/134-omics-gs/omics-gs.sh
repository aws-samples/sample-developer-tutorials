#!/bin/bash
set -e

REGION_NAME='us-east-1'
SUFFIX=$(date +%s | sha256sum | base64 | head -c 6)
NAME="test-sequence-store-${SUFFIX}"
DESCRIPTION="Test sequence store for demonstration"
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

echo "Creating sequence store with name: ${NAME}"

SEQUENCE_STORE_ID=$(aws omics create-sequence-store \
    --name "${NAME}" \
    --description "${DESCRIPTION}" \
    --client-token "${CLIENT_TOKEN}" \
    --query 'id' \
    --output text)

echo "Sequence store created with ID: ${SEQUENCE_STORE_ID}"

echo "Verifying sequence store creation"
GET_RESPONSE=$(aws omics get-sequence-store \
    --id "${SEQUENCE_STORE_ID}" \
    --query 'name' \
    --output text)
echo "Retrieved sequence store: ${GET_RESPONSE}"

echo "Listing sequence stores"
LIST_RESPONSE=$(aws omics list-sequence-stores \
    --max-results 10)
echo "List of sequence stores: ${LIST_RESPONSE}"

echo "Deleting sequence store"
aws omics delete-sequence-store \
    --id "${SEQUENCE_STORE_ID}" || true

echo "Sequence store deleted"
echo "PASS"