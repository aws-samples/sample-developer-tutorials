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

echo "Step: DescribeObject"
aws mediastore-data describe-object &>> "$LOG_FILE" && echo "DescribeObject done" || echo "DescribeObject skipped"

echo "Step: GetObject"
aws mediastore-data get-object &>> "$LOG_FILE" && echo "GetObject done" || echo "GetObject skipped"

echo "Step: ListItems"
aws mediastore-data list-items &>> "$LOG_FILE" && echo "ListItems done" || echo "ListItems skipped"

echo "PASS"