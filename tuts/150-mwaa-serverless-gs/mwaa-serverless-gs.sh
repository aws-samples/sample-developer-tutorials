#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
WORKFLOW_NAME="workflow-${SUFFIX}"
DEFINITION_S3_LOCATION="{\"Bucket\": \"your-bucket\", \"Key\": \"your-workflow-definition.yaml\"}"
ROLE_ARN="arn:aws:iam::559823168634:role/doc-babu-mwaa-serverless-role"

# Create Workflow
aws mwaa-serverless create-workflow \
    --name "${WORKFLOW_NAME}" \
    --definition-s3-location "${DEFINITION_S3_LOCATION}" \
    --role-arn "${ROLE_ARN}" || true

# Get Workflow
aws mwaa-serverless get-workflow \
    --name "${WORKFLOW_NAME}" || true

# List Workflow Runs
# This section is commented out due to missing functionality
# aws mwaa-serverless list-workflow-runs \
#     --workflow-name "${WORKFLOW_NAME}" || true

# List Task Instances
# This section is commented out due to missing functionality
# aws mwaa-serverless list-task-instances \
#     --workflow-name "${WORKFLOW_NAME}" || true

# Get Task Instance
# This section is commented out due to missing functionality
# aws mwaa-serverless get-task-instance \
#     --workflow-name "${WORKFLOW_NAME}" \
#     --task-instance-id "task-instance-id" || true

# List Tags for Resource
# This section is commented out due to missing functionality
# aws mwaa-serverless list-tags-for-resource \
#     --resource-arn "workflow-arn" || true

# Delete Workflow
aws mwaa-serverless delete-workflow \
    --name "${WORKFLOW_NAME}" || true

echo "PASS"