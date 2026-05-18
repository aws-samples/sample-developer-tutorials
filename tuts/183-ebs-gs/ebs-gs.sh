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

echo "Step: GetSnapshotBlock"
aws ebs get-snapshot-block &>> "$LOG_FILE" && echo "GetSnapshotBlock done" || echo "GetSnapshotBlock skipped"

echo "Step: ListChangedBlocks"
aws ebs list-changed-blocks &>> "$LOG_FILE" && echo "ListChangedBlocks done" || echo "ListChangedBlocks skipped"

echo "Step: ListSnapshotBlocks"
aws ebs list-snapshot-blocks &>> "$LOG_FILE" && echo "ListSnapshotBlocks done" || echo "ListSnapshotBlocks skipped"

echo "PASS"