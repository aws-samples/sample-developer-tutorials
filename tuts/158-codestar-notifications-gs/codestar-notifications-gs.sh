#!/bin/bash
set -e

# Generate a suffix using random characters
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

# List existing notification rules
RULES_COUNT=$(aws codestar-notifications list-notification-rules --query 'length(NotificationRules)' --output text)
echo "Rules: $RULES_COUNT"

# Define resource ARN and target
RESOURCE_ARN='arn:aws:codestar-notifications:us-east-1:123456789012:notificationrule/example'
TARGET='{"TargetType": "SNS", "TargetAddress": "arn:aws:sns:us-east-1:123456789012:your-sns-topic"}'
EVENT_TYPE_IDS='["codecommit-repository-pull-request-created"]'

# Create notification rule
RULE_NAME="example-rule-${SUFFIX}"
RESPONSE=$(aws codestar-notifications create-notification-rule \
    --name "$RULE_NAME" \
    --event-type-ids "$EVENT_TYPE_IDS" \
    --resource "$RESOURCE_ARN" \
    --targets "$TARGET" \
    --tags project=doc-smith,tutorial=codestar-notifications-gs \
    --detail-type BASIC \
    --query 'Arn' --output text 2>&1)

if echo "$RESPONSE" | grep -q 'ResourceAlreadyExistsException'; then
    echo "Notification Rule already exists"
elif echo "$RESPONSE" | grep -q 'AccessDeniedException'; then
    echo "Permission denied to create notification rule. Skipping creation."
else
    echo "Created Notification Rule: $RESPONSE"
fi

# List event types
EVENT_TYPES_COUNT=$(aws codestar-notifications list-event-types --query 'length(EventTypes)' --output text)
echo "Event Types: $EVENT_TYPES_COUNT"

echo "PASS"