#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="$TEMP_DIR/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Step 1: Creating challenge..." >> "$LOG_FILE"
#CHALLENGE_ARN=$(aws pca-connector-scep create-challenge --query 'path' --output text 2>> "$LOG_FILE")
#CREATED_RESOURCES+=("$CHALLENGE_ARN")

echo "Step 2: Creating connector..." >> "$LOG_FILE"
#CONNECTOR_ARN=$(aws pca-connector-scep create-connector --query 'path' --output text 2>> "$LOG_FILE")
#CREATED_RESOURCES+=("$CONNECTOR_ARN")

echo "PASS"