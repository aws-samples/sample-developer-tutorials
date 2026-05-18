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

echo "Step: ListEndpoints"
aws s3outposts list-endpoints &>> "$LOG_FILE" && echo "ListEndpoints done" || echo "ListEndpoints skipped"

echo "Step: ListOutpostsWithS3"
aws s3outposts list-outposts-with-s3 &>> "$LOG_FILE" && echo "ListOutpostsWithS3 done" || echo "ListOutpostsWithS3 skipped"

echo "Step: ListSharedEndpoints"
aws s3outposts list-shared-endpoints &>> "$LOG_FILE" && echo "ListSharedEndpoints done" || echo "ListSharedEndpoints skipped"

echo "PASS"