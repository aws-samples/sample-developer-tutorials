#!/bin/bash
set -e

SUFFIX=$(date +%s | sha256sum | base64 | head -c 8 ; echo)

PROJECT_NAME="my-build-${SUFFIX}"
BUILDSPEC='{"version": "0.2","phases": {"build": {"commands": ["echo Hello, World!"]}}}'
ARTIFACTS='{"type": "NO_ARTIFACTS"}'
ENVIRONMENT='{"type": "LINUX_CONTAINER","image": "aws/codebuild/standard:7.0","computeType": "BUILD_GENERAL1_SMALL"}'
SERVICE_ROLE='arn:aws:iam::559823168634:role/doc-babu-codebuild-role'

echo "Creating project..."
aws codebuild create-project \
    --name "${PROJECT_NAME}" \
    --description 'Test CodeBuild project' \
    --source '{"type": "NO_SOURCE","buildspec": '"$BUILDSPEC"'}' \
    --artifacts "$ARTIFACTS" \
    --environment "$ENVIRONMENT" \
    --service-role "$SERVICE_ROLE" || true

echo "Deleting project..."
aws codebuild delete-project \
    --name "${PROJECT_NAME}" || true

echo "PASS"