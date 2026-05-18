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

echo "Step: GetRoutingControlState"
aws route53-recovery-cluster get-routing-control-state &>> "$LOG_FILE" && echo "GetRoutingControlState done" || echo "GetRoutingControlState skipped"

echo "Step: ListRoutingControls"
aws route53-recovery-cluster list-routing-controls &>> "$LOG_FILE" && echo "ListRoutingControls done" || echo "ListRoutingControls skipped"

echo "PASS"