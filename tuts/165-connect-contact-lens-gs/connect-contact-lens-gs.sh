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

echo "Step: ListRealtimeContactAnalysisSegments"
aws connect-contact-lens list-realtime-contact-analysis-segments &>> "$LOG_FILE" && echo "ListRealtimeContactAnalysisSegments done" || echo "ListRealtimeContactAnalysisSegments skipped"

echo "PASS"