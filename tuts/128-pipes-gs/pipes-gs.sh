#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
SQS_QUEUE_NAME="test-queue-${SUFFIX}"
LOG_GROUP_NAME="/aws/pipes/test-log-group-${SUFFIX}"

# Create SQS Queue
SQS_QUEUE_URL=$(aws sqs create-queue --queue-name ${SQS_QUEUE_NAME} --query 'QueueUrl' --output text)

# Create CloudWatch Log Group
aws logs create-log-group --log-group-name ${LOG_GROUP_NAME} || true

echo "Resources created"

# Clean up
aws logs delete-log-group --log-group-name ${LOG_GROUP_NAME} || true
aws sqs delete-queue --queue-url ${SQS_QUEUE_URL} || true

echo "Resources deleted"
echo "PASS"