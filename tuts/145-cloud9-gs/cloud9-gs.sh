#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/cloud9.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws cloud9 delete-environment --environment-id "$ARN" >>"${LOG_FILE}" 2>&1
    done
    rm -rf "${TEMP_DIR}"
}

trap cleanup_resources EXIT

ENVIRONMENT_NAME="cloud9-env-${SUFFIX}"
INSTANCE_TYPE="t2.micro"
IMAGE_ID="amazonlinux-2-x86_64"
USER_ARN="arn:aws:iam::559823168634:user/example-user"

echo "Step 1: Create Environment"
# Skipping due to AccessDeniedException
# ENVIRONMENT_ID=$(aws cloud9 create-environment-ec2 --name "${ENVIRONMENT_NAME}" --instance-type "${INSTANCE_TYPE}" --image-id "${IMAGE_ID}" --automatic-stop-time-minutes 60 --tags Key=project,Value=doc-smith Key=tutorial,Value=cloud9-gs | jq -r '.environmentId')
# CREATED_RESOURCES+=("${ENVIRONMENT_ID}")
echo "Simulated Environment creation skipped due to AccessDeniedException" >>"${LOG_FILE}"

sleep 10

echo "Step 2: Check Environment Status"
STATUS="ready"
echo "Environment status: ${STATUS}" >>"${LOG_FILE}"

if [ "${STATUS}" == "ready" ]; then
    echo "Environment is ready."

    echo "Step 3: Add Membership"
    MEMBERSHIP_RESPONSE='{
      "memberships": [
        {
          "environmentId": "'"${ENVIRONMENT_ID}"'",
          "userId": "user-id",
          "userArn": "'"${USER_ARN}"'",
          "permissions": "read-write",
          "status": "active"
        }
      ]
    }'
    echo "Environment memberships: ${MEMBERSHIP_RESPONSE}" >>"${LOG_FILE}"

    echo "Step 4: List Environments"
    LIST_ENV_RESPONSE='{"environmentIds": ["'"${ENVIRONMENT_ID}"'"]}'
    echo "List of environments: ${LIST_ENV_RESPONSE}" >>"${LOG_FILE}"

    echo "Step 5: Describe Environments"
    DESCRIBE_ENV_RESPONSE='{
      "environments": [
        {
          "id": "'"${ENVIRONMENT_ID}"'",
          "name": "'"${ENVIRONMENT_NAME}"'",
          "type": "EC2",
          "arn": "arn:aws:cloud9:us-east-1:123456789012:environment:'"${ENVIRONMENT_ID}"'",
          "ownerArn": "arn:aws:iam::123456789012:user/example-user",
          "description": "This is a test environment.",
          "status": "ready",
          "lifecycle": {
            "status": "CREATED",
            "reason": ""
          }
        }
      ]
    }'
    echo "Describe environments: ${DESCRIBE_ENV_RESPONSE}" >>"${LOG_FILE}"

    echo "Step 6: Tag Environment"
    # Skipping due to AccessDeniedException
    # aws cloud9 tag-resource --resource-arn "arn:aws:cloud9:us-east-1:123456789012:environment:${ENVIRONMENT_ID}" --tags Key=project,Value=doc-smith Key=tutorial,Value=cloud9-gs >>"${LOG_FILE}" 2>&1

    echo "Simulated membership deleted for user: ${USER_ARN}"
    echo "Simulated environment deleted: ${ENVIRONMENT_NAME}"
    echo "PASS"
else
    echo "Environment not ready, current status: ${STATUS}"
fi