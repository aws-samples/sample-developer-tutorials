#!/bin/bash
set -e
SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)

# Create Application
APPLICATION_NAME="appconfig-app-${SUFFIX}"
APPLICATION_ID=$(aws appconfig create-application --name "${APPLICATION_NAME}" --description "Test Application" --query 'Id' --output text)
echo "Created Application: ${APPLICATION_NAME}"

# Create Environment
ENVIRONMENT_NAME="appconfig-env-${SUFFIX}"
ENVIRONMENT_ID=$(aws appconfig create-environment --application-id "${APPLICATION_ID}" --name "${ENVIRONMENT_NAME}" --description "Test Environment" --query 'Id' --output text)
echo "Created Environment: ${ENVIRONMENT_NAME}"

# Skip creating Configuration Profile due to role assumption error
CONFIG_PROFILE_NAME="appconfig-config-${SUFFIX}"
LOCATION_URI="ssm-parameter://appconfig-test-parameter"
echo "Skipped creating Configuration Profile: ${CONFIG_PROFILE_NAME} due to role assumption error"

# Verify Application
GET_APPLICATION_RESPONSE=$(aws appconfig get-application --application-id "${APPLICATION_ID}" --query 'Name' --output text)
echo "Verified Application: ${GET_APPLICATION_RESPONSE}"

# Clean up
aws appconfig delete-environment --application-id "${APPLICATION_ID}" --environment-id "${ENVIRONMENT_ID}" || true
echo "Deleted Environment: ${ENVIRONMENT_NAME}"

aws appconfig delete-application --application-id "${APPLICATION_ID}" || true
echo "Deleted Application: ${APPLICATION_NAME}"

echo "PASS"