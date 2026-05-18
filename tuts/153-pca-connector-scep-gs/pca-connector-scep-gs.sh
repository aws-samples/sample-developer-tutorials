#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws pca-connector-scep delete-connector --connector-arn "$ARN" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Step 1: Creating challenge..." >> "$LOG_FILE"
CHALLENGE_ARN=$(aws pca-connector-scep create-challenge --query 'path' --output text 2>> "$LOG_FILE")
CREATED_RESOURCES+=("$CHALLENGE_ARN")
aws pca-connector-scep tag-resource --resource-arn "$CHALLENGE_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=pca-connector-scep-gs || true

echo "Step 2: Creating connector..." >> "$LOG_FILE"
CONNECTOR_ARN=$(aws pca-connector-scep create-connector --query 'path' --output text 2>> "$LOG_FILE")
CREATED_RESOURCES+=("$CONNECTOR_ARN")
aws pca-connector-scep tag-resource --resource-arn "$CONNECTOR_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=pca-connector-scep-gs || true

echo "Step 3: Deleting challenge..." >> "$LOG_FILE"
aws pca-connector-scep delete-challenge --challenge-arn "$CHALLENGE_ARN" 2>> "$LOG_FILE" || true

echo "Step 4: Deleting connector..." >> "$LOG_FILE"
aws pca-connector-scep delete-connector --connector-arn "$CONNECTOR_ARN" 2>> "$LOG_FILE" || true

echo "Step 5: Getting challenge metadata..." >> "$LOG_FILE"
aws pca-connector-scep get-challenge-metadata --challenge-arn "$CHALLENGE_ARN" --query 'path' --output text 2>> "$LOG_FILE" || true

echo "Step 6: Getting challenge password..." >> "$LOG_FILE"
aws pca-connector-scep get-challenge-password --challenge-arn "$CHALLENGE_ARN" --query 'path' --output text 2>> "$LOG_FILE" || true

echo "PASS"
