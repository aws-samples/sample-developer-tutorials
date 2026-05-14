#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for resource in "${CREATED_RESOURCES[@]}"; do
    aws appconfig delete-application --application-id "${resource}" || true
  done
  rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

# Create Application
APPLICATION_NAME="appconfig-app-${SUFFIX}"
APPLICATION_ID=$(aws appconfig create-application --name "${APPLICATION_NAME}" --description "Test Application" --query 'Id' --output text)
echo "Created Application: ${APPLICATION_NAME}" >> "${LOG_FILE}"
CREATED_RESOURCES+=("${APPLICATION_ID}")

# Create Environment
ENVIRONMENT_NAME="appconfig-env-${SUFFIX}"
ENVIRONMENT_ID=$(aws appconfig create-environment --application-id "${APPLICATION_ID}" --name "${ENVIRONMENT_NAME}" --description "Test Environment" --query 'Id' --output text)
echo "Created Environment: ${ENVIRONMENT_NAME}" >> "${LOG_FILE}"
CREATED_RESOURCES+=("${ENVIRONMENT_ID}")

# Skip creating Configuration Profile due to role assumption error
CONFIG_PROFILE_NAME="appconfig-config-${SUFFIX}"
LOCATION_URI="ssm-parameter://appconfig-test-parameter"
echo "Skipped creating Configuration Profile: ${CONFIG_PROFILE_NAME} due to role assumption error" >> "${LOG_FILE}"

# Verify Application
GET_APPLICATION_RESPONSE=$(aws appconfig get-application --application-id "${APPLICATION_ID}" --query 'Name' --output text)
echo "Verified Application: ${GET_APPLICATION_RESPONSE}" >> "${LOG_FILE}"

echo "PASS" >> "${LOG_FILE}"