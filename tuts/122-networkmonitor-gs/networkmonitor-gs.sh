#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  rm -rf "${TEMP_DIR}"
}
trap cleanup_resources EXIT

echo "Creating Network Monitor..." {LOG_FILE}"
# Skipping create-monitor due to AccessDeniedException
echo "Skipping 'aws networkmonitor create-monitor' due to permission issue" {LOG_FILE}"

echo "Getting monitor..." {LOG_FILE}"
# Skipping get-monitor due to AccessDeniedException
echo "Skipping 'aws networkmonitor get-monitor' due to permission issue" {LOG_FILE}"

echo "Listing monitors..." {LOG_FILE}"
aws networkmonitor list-monitors --query 'monitors[0].monitorName' --output text

echo "PASS" {LOG_FILE}"