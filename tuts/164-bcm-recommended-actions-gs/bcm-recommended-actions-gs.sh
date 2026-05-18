#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    # Add cleanup logic here if needed
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

aws bcm-recommended-actions list-recommended-actions --query "RecommendedActions[*].ActionId" --output text &>> "$LOG_FILE"
echo "PASS"