#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(date +%s | sha256sum | base64 | head -c 6)
APP_NAME="my-app-${SUFFIX}"

echo "Creating Pinpoint application with name: ${APP_NAME}"
APP_ID=$(aws pinpoint create-app --create-application-request '{"Name":"'${APP_NAME}'"}' --query 'ApplicationResponse.Id' --output text --region ${REGION})
echo "Pinpoint application created with ID: ${APP_ID}"

echo "Retrieving the newly created application"
aws pinpoint get-app --application-id ${APP_ID} --region ${REGION}

echo "Listing all applications"
aws pinpoint get-apps --region ${REGION}

echo "Deleting Pinpoint application with ID: ${APP_ID}"
aws pinpoint delete-app --application-id ${APP_ID} --region ${REGION} || true

echo "PASS"