#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/log.txt"
declare -a CREATED_RESOURCES=()

cleanup_resources() {
    for (( i=${#CREATED_RESOURCES[@]}-1; i>=0; i-- )); do
        RESOURCE=(${CREATED_RESOURCES[i]})
        case ${RESOURCE[0]} in
            "pinpoint-app") aws pinpoint delete-app --application-id ${RESOURCE[1]} --region ${REGION} ;;
        esac
    done
    rm -rf ${TEMP_DIR}
}
trap cleanup_resources EXIT

echo "=== Creating Pinpoint application ==="
APP_NAME="my-app-${SUFFIX}"
APP_ID=$(aws pinpoint create-app --create-application-request '{"Name":"'${APP_NAME}'"}' --query 'ApplicationResponse.Id' --output text --region ${REGION})
echo "Pinpoint application created with ID: ${APP_ID}"
CREATED_RESOURCES+=("pinpoint-app:${APP_ID}")

echo "=== Retrieving the newly created application ==="
aws pinpoint get-app --application-id ${APP_ID} --region ${REGION}

echo "=== Listing all applications ==="
aws pinpoint get-apps --region ${REGION}

echo "PASS" >> ${LOG_FILE}