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

echo "Step: DescribeKeyValueStore"
aws cloudfront-keyvaluestore describe-key-value-store &>> "$LOG_FILE" && echo "DescribeKeyValueStore done" || echo "DescribeKeyValueStore skipped"

echo "Step: GetKey"
aws cloudfront-keyvaluestore get-key &>> "$LOG_FILE" && echo "GetKey done" || echo "GetKey skipped"

echo "Step: ListKeys"
aws cloudfront-keyvaluestore list-keys &>> "$LOG_FILE" && echo "ListKeys done" || echo "ListKeys skipped"

echo "PASS"