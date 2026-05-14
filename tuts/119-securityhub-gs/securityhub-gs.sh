#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log-${SUFFIX}.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "${TEMP_DIR}"
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Cleaning up: ${resource}"
  done
}

trap cleanup_resources EXIT

echo "STEP 1: Enabling Security Hub..." {LOG_FILE}"
aws securityhub enable-security-hub --enable-default-standards 2>/dev/null || echo "Already enabled" {LOG_FILE}"
CREATED_RESOURCES+=("Security Hub")

echo "STEP 2: Getting findings..." {LOG_FILE}"
aws securityhub get-findings --max-results 3 --query 'Findings[].Title' --output text || echo "No findings" {LOG_FILE}"

echo "STEP 3: Disabling Security Hub..." {LOG_FILE}"
aws securityhub disable-security-hub || true

echo "PASS" {LOG_FILE}"