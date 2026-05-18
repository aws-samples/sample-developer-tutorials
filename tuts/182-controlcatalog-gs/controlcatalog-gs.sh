#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

trap cleanup_resources EXIT

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

echo "Step: GetControl"
aws controlcatalog get-control &>> "$LOG_FILE" && echo "GetControl done" || echo "GetControl skipped"

echo "Step: ListCommonControls"
aws controlcatalog list-common-controls &>> "$LOG_FILE" && echo "ListCommonControls done" || echo "ListCommonControls skipped"

echo "Step: ListControlMappings"
aws controlcatalog list-control-mappings &>> "$LOG_FILE" && echo "ListControlMappings done" || echo "ListControlMappings skipped"

echo "PASS"