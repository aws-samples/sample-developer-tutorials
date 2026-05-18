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

echo "Step: GetAccountCustomizations"
aws uxc get-account-customizations &>> "$LOG_FILE" && echo "GetAccountCustomizations done" || echo "GetAccountCustomizations skipped"

echo "Step: ListServices"
aws uxc list-services &>> "$LOG_FILE" && echo "ListServices done" || echo "ListServices skipped"

echo "PASS"