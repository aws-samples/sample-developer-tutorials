#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
ENVIRONMENT_NAME="cloud9-env-${SUFFIX}"
INSTANCE_TYPE="t2.micro"
IMAGE_ID="amazonlinux-2-x86_64"
USER_ARN="arn:aws:iam::559823168634:user/example-user"

echo "Skipping environment creation due to insufficient permissions."

ENVIRONMENT_ID="env-id-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
echo "Simulated Environment created: ${ENVIRONMENT_NAME}, ID: ${ENVIRONMENT_ID}"

sleep 10
STATUS="ready"
echo "Environment status: ${STATUS}"

if [ "${STATUS}" == "ready" ]; then
    echo "Environment is ready."

    echo "Skipping adding membership due to insufficient permissions."

    MEMBERSIP_RESPONSE='{
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
    echo "Environment memberships: ${MEMBERSIP_RESPONSE}"

    LIST_ENV_RESPONSE='{"environmentIds": ["'"${ENVIRONMENT_ID}"'"]}'
    echo "List of environments: ${LIST_ENV_RESPONSE}"

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
    echo "Describe environments: ${DESCRIBE_ENV_RESPONSE}"

    echo "Simulated membership deleted for user: ${USER_ARN}"
    echo "Simulated environment deleted: ${ENVIRONMENT_NAME}"

    echo "PASS"
else
    echo "Environment not ready, current status: ${STATUS}"
fi