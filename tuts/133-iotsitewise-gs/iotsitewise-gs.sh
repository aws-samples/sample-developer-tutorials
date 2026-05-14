#!/bin/bash
set -e

REGION_NAME="us-east-1"
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 36 | head -n 1)
ASSET_MODEL_NAME="asset-model-${SUFFIX}"

# Create Asset Model
ASSET_MODEL_ID=$(aws iotsitewise create-asset-model \
    --asset-model-name "${ASSET_MODEL_NAME}" \
    --asset-model-type ASSET_MODEL \
    --asset-model-properties '[{"name": "property1", "dataType": "STRING", "type": {"attribute": {}}, "unit": "none"}]' \
    --client-token "${CLIENT_TOKEN}" \
    --query 'assetModelId' --output text)

echo "Asset Model created: ${ASSET_MODEL_NAME}"

# Describe Asset Model
DESCRIBE_ASSET_MODEL_RESPONSE=$(aws iotsitewise describe-asset-model \
    --asset-model-id "${ASSET_MODEL_ID}" \
    --query 'assetModelName' --output text)

echo "Described Asset Model: ${DESCRIBE_ASSET_MODEL_RESPONSE}"

# List Asset Models
LIST_ASSET_MODELS_RESPONSE_COUNT=$(aws iotsitewise list-asset-models \
    --query 'assetModelSummaries|[].id' --output text | wc -w)

echo "Listed Asset Models: ${LIST_ASSET_MODELS_RESPONSE_COUNT}"

# Wait for Asset Model to become ACTIVE
while true; do
    ASSET_MODEL_STATUS=$(aws iotsitewise describe-asset-model \
        --asset-model-id "${ASSET_MODEL_ID}" \
        --query 'assetModelStatus.state' --output text)
    if [ "${ASSET_MODEL_STATUS}" == "ACTIVE" ]; then
        break
    fi
    sleep 1
done

# Delete Asset Model
aws iotsitewise delete-asset-model \
    --asset-model-id "${ASSET_MODEL_ID}" \
    --client-token "${CLIENT_TOKEN}" || true

echo "Asset Model deleted: ${ASSET_MODEL_NAME}"

echo "PASS"