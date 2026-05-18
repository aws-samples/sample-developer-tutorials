#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws serverlessrepo delete-application --application-id "$ARN" || true
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT

# Step 1: Create Application
APPLICATION_NAME="doc-smith-app-${SUFFIX}"
VERSION="1.0.0"
TEMPLATE_BODY='{"Transform": "AWS::Serverless-2016-10-31","Resources": {"SampleResource": {"Type": "AWS::S3::Bucket","Properties": {"BucketName": "doc-smith-bucket-'"${SUFFIX}"'"}}}}'

APPLICATION_ID=$(aws serverlessrepo create-application \
    --author 'doc-smith' \
    --description 'Sample application for serverlessrepo tutorial' \
    --name "${APPLICATION_NAME}" \
    --labels 'project:doc-smith' 'tutorial:serverlessrepo-gs' \
    --query 'ApplicationId' --output text)
CREATED_RESOURCES+=("$APPLICATION_ID")

echo "Application created: ${APPLICATION_ID}"

# Step 2: Get Application
aws serverlessrepo get-application \
    --application-id "${APPLICATION_ID}" \
    --query 'Name' --output text

# Step 3: Create Application Version
aws serverlessrepo create-application-version \
    --application-id "${APPLICATION_ID}" \
    --semantic-version "${VERSION}" \
    --template-body "${TEMPLATE_BODY}"

# Step 4: Delete Application
aws serverlessrepo delete-application \
    --application-id "${APPLICATION_ID}" || true

echo "PASS"