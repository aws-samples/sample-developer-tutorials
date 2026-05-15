# Iotsitewise Asset Model Management Tutorial

## Prerequisites

- Aws cli installed and configured with appropriate permissions.
- A working iotsitewise environment.

## Steps

**1. Create asset model**

```bash
$ REGION_NAME="us-east-1"
$ SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
$ ASSET_MODEL_NAME="asset-model-${SUFFIX}"
$ ASSET_MODEL_ID=$(aws iotsitewise create-asset-model \
    --asset-model-name "${ASSET_MODEL_NAME}" \
    --asset-model-type ASSET_MODEL \
    --asset-model-properties '[{"name": "property1", "dataType": "STRING", "type": {"attribute": {}}, "unit": "none"}]' \
    --client-token "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 36 | head -n 1)" \
    --tags '{"project": "doc-smith", "tutorial": "iotsitewise-gs"}' \
    --query 'assetModelId' --output text)
$ echo "Asset Model created: ${ASSET_MODEL_NAME}"
```

**2. Describe asset model**

```bash
$ DESCRIBE_ASSET_MODEL_RESPONSE=$(aws iotsitewise describe-asset-model \
    --asset-model-id "${ASSET_MODEL_ID}" \
    --query 'assetModelName' --output text)
$ echo "Described Asset Model: ${DESCRIBE_ASSET_MODEL_RESPONSE}"
```

**3. List asset models**

```bash
$ LIST_ASSET_MODELS_RESPONSE_COUNT=$(aws iotsitewise list-asset-models \
    --query 'assetModelSummaries|[].id' --output text | wc -w)
$ echo "Listed Asset Models: ${LIST_ASSET_MODELS_RESPONSE_COUNT}"
```

**4. Wait for asset model to become active**

```bash
$ while true; do
    ASSET_MODEL_STATUS=$(aws iotsitewise describe-asset-model \
        --asset-model-id "${ASSET_MODEL_ID}" \
        --query 'assetModelStatus.state' --output text)
    if [ "${ASSET_MODEL_STATUS}" == "ACTIVE" ]; then
        break
    fi
    sleep 1
done
```

## Clean up

The script includes a cleanup function that deletes the created asset model and removes temporary files.

## Next steps

Explore more iotsitewise features and integrate them into your iot solutions.