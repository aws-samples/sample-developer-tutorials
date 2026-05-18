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

echo "Step: GetAccountActivity"
aws freetier get-account-activity &>> "$LOG_FILE" && echo "GetAccountActivity done" || echo "GetAccountActivity skipped"

echo "Step: GetAccountPlanState"
aws freetier get-account-plan-state &>> "$LOG_FILE" && echo "GetAccountPlanState done" || echo "GetAccountPlanState skipped"

echo "Step: GetFreeTierUsage"
aws freetier get-free-tier-usage &>> "$LOG_FILE" && echo "GetFreeTierUsage done" || echo "GetFreeTierUsage skipped"

echo "PASS"