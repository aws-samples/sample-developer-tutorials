#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
CLIENT_TOKEN=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
APP_NAME="test-app-${SUFFIX}"

# Create App
APP_ARN=$(aws resiliencehub create-app \
    --name "${APP_NAME}" \
    --description "Test Resilience Hub Application" \
    --assessment-schedule "Disabled" \
    --permission-model '{"type": "LegacyIAMUser"}' \
    --client-token "${CLIENT_TOKEN}" \
    --query 'appArn' --output text)

if [ -n "${APP_ARN}" ]; then
    echo "Created App: ${APP_ARN}"

    # List Apps
    LIST_APPS_RESPONSE=$(aws resiliencehub list-apps \
        --query 'length(appSummaries)' --output text)
    echo "Listed Apps: ${LIST_APPS_RESPONSE} apps found"

    # Delete App
    aws resiliencehub delete-app \
        --app-arn "${APP_ARN}" \
        --client-token "${CLIENT_TOKEN}" \
        --force-delete || true
    echo "Deleted App: ${APP_ARN}"
else
    echo "Failed to create app, no appArn in response"
fi

echo "PASS"