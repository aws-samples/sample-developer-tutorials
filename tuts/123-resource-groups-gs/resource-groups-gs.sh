#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
GROUP_NAME="group-${SUFFIX}"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for resource in "${CREATED_RESOURCES[@]}"; do
        echo "Cleaning up: $resource"
        aws resource-groups delete-group --group-name "$resource" || true
    done
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "=== Creating group ==="
aws resource-groups create-group \
    --name "$GROUP_NAME" \
    --resource-query '{"Type":"TAG_FILTERS_1_0","Query":"{\"ResourceTypeFilters\":[\"AWS::AllSupported\"],\"TagFilters\":[{\"Key\":\"project\",\"Values\":[\"doc-smith\"]}]}"}' \
    --generate-cli-skeleton > "$LOG_FILE"
CREATED_RESOURCES+=("$GROUP_NAME")

echo "=== Listing groups ==="
aws resource-groups list-groups \
    --generate-cli-skeleton >> "$LOG_FILE"

echo "=== Deleting group ==="
aws resource-groups delete-group \
    --group-name "$GROUP_NAME" || true

echo "PASS"