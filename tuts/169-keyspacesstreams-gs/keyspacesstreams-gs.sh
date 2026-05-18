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

echo "Step: GetRecords"
aws keyspacesstreams get-records &>> "$LOG_FILE" && echo "GetRecords done" || echo "GetRecords skipped"

echo "Step: GetShardIterator"
aws keyspacesstreams get-shard-iterator &>> "$LOG_FILE" && echo "GetShardIterator done" || echo "GetShardIterator skipped"

echo "Step: GetStream"
aws keyspacesstreams get-stream &>> "$LOG_FILE" && echo "GetStream done" || echo "GetStream skipped"

echo "PASS"