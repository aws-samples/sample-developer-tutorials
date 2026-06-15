#!/bin/bash
set -e

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Cleaning up: $resource"
    case $resource in
      "asset-model:"*)
        asset_model_id=$(echo $resource | cut -d ':' -f 2-)
        aws iotsitewise delete-asset-model --asset-model-id $asset_model_id || true
        ;;
      "asset:"*)
        asset_id=$(echo $resource | cut -d ':' -f 2-)
        aws iotsitewise delete-asset --asset-id $asset_id || true
        ;;
      "access-policy:"*)
        access_policy_id=$(echo $resource | cut -d ':' -f 2-)
        aws iotsitewise delete-access-policy --access-policy-id $access_policy_id || true
        ;;
      *)
        echo "Unknown resource type: $resource"
        ;;
    esac
  done
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
CREATED_RESOURCES=()

echo "Creating an asset model..."
ASSET_MODEL_NAME="TutorialAssetModel$SUFFIX"
ASSET_MODEL_ID=$(aws iotsitewise create-asset-model --asset-model-name $ASSET_MODEL_NAME --tags '{"Environment":"Tutorial"}' --query 'assetModelId' --output text)
CREATED_RESOURCES+=("asset-model:$ASSET_MODEL_ID")

echo "Verifying the created asset model..."
aws iotsitewise describe-asset-model --asset-model-id $ASSET_MODEL_ID

echo "Creating an asset from the asset model..."
ASSET_NAME="TutorialAsset$SUFFIX"
ASSET_ID=$(aws iotsitewise create-asset --asset-name $ASSET_NAME --asset-model-id $ASSET_MODEL_ID --tags '{"Environment":"Tutorial"}' --query 'assetId' --output text)
CREATED_RESOURCES+=("asset:$ASSET_ID")

echo "Verifying the created asset..."
aws iotsitewise describe-asset --asset-id $ASSET_ID

echo "Creating an access policy for the asset..."
ACCESS_POLICY_ID=$(aws iotsitewise create-access-policy --access-policy-permission 'ADMIN' --access-policy-identity-type 'IAM' --access-policy-resource-type 'ASSET' --access-policy-resource-id $ASSET_ID --access-policy-identity-id $ROLE_ARN --tags '{"Environment":"Tutorial"}' --query 'accessPolicyId' --output text)
CREATED_RESOURCES+=("access-policy:$ACCESS_POLICY_ID")

echo "Verifying the created access policy..."
aws iotsitewise describe-access-policy --access-policy-id $ACCESS_POLICY_ID

echo "PASS"
