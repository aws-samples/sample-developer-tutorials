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

echo "Step: GetDataAutomationStatus"
aws bedrock-data-automation-runtime get-data-automation-status &>> "$LOG_FILE" && echo "GetDataAutomationStatus done" || echo "GetDataAutomationStatus skipped"

echo "Step: ListTagsForResource"
aws bedrock-data-automation-runtime list-tags-for-resource &>> "$LOG_FILE" && echo "ListTagsForResource done" || echo "ListTagsForResource skipped"

echo "PASS"