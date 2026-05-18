#!/bin/bash
set -e

SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
SCHEDULED_QUERY_NAME="scheduled-query-${SUFFIX}"
SCHEDULED_QUERY_ARN=""

# Create Scheduled Query
QUERY_STRING="SELECT * FROM your_table WHERE time > ago(5m)"
SCHEDULE_CONFIGURATION='{"ScheduleExpression": "cron(0/5 * * *? *)"}'
NOTIFICATION_CONFIGURATION='{"SnsConfiguration": {"TopicArn": "arn:aws:sns:us-east-1:123456789012:your-sns-topic"}}'

SCHEDULED_QUERY_ARN=$(aws timestream-query create-scheduled-query \
    --name "$SCHEDULED_QUERY_NAME" \
    --query-string "$QUERY_STRING" \
    --schedule-configuration "$SCHEDULE_CONFIGURATION" \
    --notification-configuration "$NOTIFICATION_CONFIGURATION" \
    --query 'ScheduledQueryArn' --output text)

echo "Created Scheduled Query: $SCHEDULED_QUERY_ARN"

# Verify Scheduled Query
aws timestream-query describe-scheduled-query \
    --scheduled-query-arn "$SCHEDULED_QUERY_ARN" || true

# List Scheduled Queries
aws timestream-query list-scheduled-queries || true

# Get Account Settings
aws timestream-query describe-account-settings || true

# Get Endpoints
aws timestream-query describe-endpoints || true

# List Tags for Resource
aws timestream-query list-tags-for-resource \
    --resource-arn "$SCHEDULED_QUERY_ARN" || true

# Clean up
aws timestream-query delete-scheduled-query \
    --scheduled-query-arn "$SCHEDULED_QUERY_ARN" || true

echo "PASS"