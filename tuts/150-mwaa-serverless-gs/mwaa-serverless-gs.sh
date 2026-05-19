#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

WORKFLOW_NAME="workflow-${SUFFIX}"
DEFINITION_S3_LOCATION="{\"Bucket\": \"your-bucket\", \"ObjectKey\": \"your-workflow-definition.yaml\"}"
ROLE_ARN="${TUTORIAL_ROLE_ARN:?Set TUTORIAL_ROLE_ARN to an IAM role ARN with mwaa permissions}"

# Step 1: Create Workflow
echo "Step 1: Creating Workflow"
ARN=$(aws mwaa-serverless create-workflow \
    --name "${WORKFLOW_NAME}" \
    --definition-s3-location "${DEFINITION_S3_LOCATION}" \
    --role-arn "${ROLE_ARN}" \
    --tags Key=project,Value=doc-smith --tags Key=tutorial,Value=mwaa-serverless-gs | jq -r '.Arn')
CREATED_RESOURCES+=("$ARN")

echo "PASS"