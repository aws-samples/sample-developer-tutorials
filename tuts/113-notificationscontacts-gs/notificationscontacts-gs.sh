#!/bin/bash
set -e

SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
NAME="contact${SUFFIX}"
EMAIL_ADDRESS="test${SUFFIX}@example.com"

echo "Creating email contact..."
TOPIC_ARN=$(aws sns create-topic --name "$NAME" --attributes '{"DisplayName":"'"$EMAIL_ADDRESS"'"}' --query 'TopicArn' --output text)
echo "Email contact created with ARN: $TOPIC_ARN"

sleep 5  # Wait for the contact to become active

echo "Listing topics..."
aws sns list-topics --query 'Topics' --output json

echo "Deleting email contact..."
aws sns delete-topic --topic-arn "$TOPIC_ARN" || true
echo "Email contact deleted"

sleep 5  # Wait for the deletion to complete

echo "PASS"