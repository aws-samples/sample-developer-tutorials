#!/bin/bash
set -e
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() { rm -rf "$TEMP_DIR"; }
trap cleanup_resources EXIT
echo "=== Listing Data Lakes ==="
aws securitylake list-data-lakes --query 'dataLakes[].dataLakeArn' --output text || echo "No data lakes"
echo "=== Listing Sources ==="
aws securitylake list-log-sources --query 'account' --output text 2>/dev/null || echo "No sources"
echo "=== Tutorial Complete ==="
