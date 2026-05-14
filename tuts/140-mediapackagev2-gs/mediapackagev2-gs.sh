#!/bin/bash
set -e

TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        echo "Cleaning up: $resource"
        aws mediapackagev2 delete-channel-group --channel-group-name "$resource" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
CHANNEL_GROUP_NAME="test-channel-group-${SUFFIX}"
CLIENT_TOKEN=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# Create Channel Group
echo "Step 1: Creating Channel Group..."
aws mediapackagev2 create-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" \
    --client-token "$CLIENT_TOKEN" \
    --description "Test Channel Group" \
    --tags Environment=Test 2>>"$LOG_FILE"
CREATED_RESOURCES+=("$CHANNEL_GROUP_NAME")

# Verify Channel Group Creation
echo "Step 2: Verifying Channel Group Creation..."
aws mediapackagev2 get-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" 2>>"$LOG_FILE"

# List Channel Groups
echo "Step 3: Listing Channel Groups..."
aws mediapackagev2 list-channel-groups \
    --max-results 10 2>>"$LOG_FILE"

# Delete Channel Group
echo "Step 4: Deleting Channel Group..."
aws mediapackagev2 delete-channel-group \
    --channel-group-name "$CHANNEL_GROUP_NAME" 2>>"$LOG_FILE"

echo "PASS"