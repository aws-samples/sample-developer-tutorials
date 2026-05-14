#!/bin/bash
set -e

REGION="us-east-1"
SUFFIX=$(date +%s)$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
REPO_NAME="test-repo-${SUFFIX}"

echo "Creating repository..."
REPOSITORY_ARN=$(aws codecommit create-repository --repository-name "${REPO_NAME}" --query 'repositoryMetadata.repositoryArn' --output text)

if [ -n "${REPOSITORY_ARN}" ]; then
    echo "PASS"
else
    echo "Failed to retrieve repository ARN."
    exit 1
fi

# Cleanup
aws codecommit delete-repository --repository-name "${REPO_NAME}" || true
echo "Repository deleted."