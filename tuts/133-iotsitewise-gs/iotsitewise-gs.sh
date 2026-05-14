#!/bin/bash
set -e

REGION_NAME="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        aws iotsitewise delete-asset-model --asset-model-id "$resource" --client-token "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1)" || true
    done
    rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

# Create Asset Model
ASSET_MODEL_NAME="asset-model-${SUFFIX}"
ASSET_MODEL_ID=$(aws iotsitewise create-asset-model \
    --asset-model-name "${ASSET_MODEL_NAME}" \
    --asset-model-type ASSET_MODEL \
    --asset-model-properties '[{"name": "property1", "dataType": "STRING", "type": {"attribute": {}}, "unit": "none"}]' \
    --client-token "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1)" \
    --query 'assetModelId' --output text)
CREATED_RESOURCES+=("${ASSET_MODEL_ID}")
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
    --client-token "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1)" || true

echo "Asset Model deleted: ${ASSET_MODEL_NAME}"

echo "PASS"