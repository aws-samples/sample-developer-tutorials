#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
NAME="contact${SUFFIX}"
EMAIL_ADDRESS="test${SUFFIX}@example.com"
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
  for ARN in "${CREATED_RESOURCES[@]}"; do
    aws sns delete-topic --topic-arn "$ARN" || true
  done
  rm -rf "$TEMP_DIR"
}

trap cleanup_resources EXIT

echo "Creating email contact..." 
TOPIC_ARN=$(aws sns create-topic --name "$NAME" --attributes '{"DisplayName":"'"$EMAIL_ADDRESS"'"}' --query 'TopicArn' --output text)
aws sns tag-resource --resource-arn "$TOPIC_ARN" --tags Key=project,Value=doc-smith Key=tutorial,Value=notificationscontacts-gs
echo "Email contact created with ARN: $TOPIC_ARN" 
CREATED_RESOURCES+=("$TOPIC_ARN")

sleep 5  # Wait for the contact to become active

echo "Listing topics..." 
aws sns list-topics --query 'Topics' --output json 

echo "Deleting email contact..." 
aws sns delete-topic --topic-arn "$TOPIC_ARN" || true
echo "Email contact deleted" 

sleep 5  # Wait for the deletion to complete

echo "PASS"
