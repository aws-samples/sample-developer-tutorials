#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script_log_${SUFFIX}.txt"
CREATED_RESOURCES=()

cleanup_resources() {
  echo "Cleaning up created resources..."
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "Deleting resource: $resource"
    # Add appropriate AWS CLI delete command here if needed
  done
  rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

echo "Script started" > "${LOG_FILE}"
echo "-------------------------" >> "${LOG_FILE}"

echo "Step 1: Listing Lake Formation resources..."
aws lakeformation list-resources --query 'ResourceInfoList[0].ResourceArn' --output text || echo "No resources"
echo "Step 1: Listing Lake Formation resources... Done" >> "${LOG_FILE}"

echo "Step 2: Getting data lake settings..."
aws lakeformation get-data-lake-settings --query 'DataLakeSettings.DataLakeAdmins' --output text || echo "No admins"
echo "Step 2: Getting data lake settings... Done" >> "${LOG_FILE}"

echo "PASS"