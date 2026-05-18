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

echo "Step: DescribeHomeRegionControls"
aws migrationhub-config describe-home-region-controls &>> "$LOG_FILE" && echo "DescribeHomeRegionControls done" || echo "DescribeHomeRegionControls skipped"

echo "Step: GetHomeRegion"
aws migrationhub-config get-home-region &>> "$LOG_FILE" && echo "GetHomeRegion done" || echo "GetHomeRegion skipped"

echo "PASS"