#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)

SCHEDULED_QUERY_NAME="scheduled-query-${SUFFIX}"
SCHEDULED_QUERY_ARN=""

# Create Scheduled Query
QUERY_STRING="SELECT * FROM your_table WHERE time > ago(5m)"
SCHEDULE_CONFIGURATION='{"ScheduleExpression": "cron(0/5 * * *? *)"}'
NOTIFICATION_CONFIGURATION='{"SnsConfiguration": {"TopicArn": "arn:aws:sns:us-east-1:123456789012:your-sns-topic"}}'

aws timestream-query create-scheduled-query \
    --name "${SCHEDULED_QUERY_NAME}" \
    --query-string "${QUERY_STRING}" \
    --schedule-configuration "${SCHEDULE_CONFIGURATION}" \
    --notification-configuration "${NOTIFICATION_CONFIGURATION}" \
    --query 'ScheduledQueryArn' --output text | tee scheduled_query_arn.txt

SCHEDULED_QUERY_ARN=$(cat scheduled_query_arn.txt)
echo "Created Scheduled Query: ${SCHEDULED_QUERY_ARN}"

# Verify Scheduled Query
aws timestream-query describe-scheduled-query \
    --scheduled-query-arn "${SCHEDULED_QUERY_ARN}" \
    --query 'ScheduledQuery' --output json | tee described_scheduled_query.json
echo "Described Scheduled Query: $(cat described_scheduled_query.json)"

# List Scheduled Queries
aws timestream-query list-scheduled-queries \
    --query 'ScheduledQueries' --output json | tee listed_scheduled_queries.json
echo "Listed Scheduled Queries: $(cat listed_scheduled_queries.json)"

# Get Account Settings
aws timestream-query describe-account-settings \
    --query 'AccountSettings' --output json | tee account_settings.json
echo "Described Account Settings: $(cat account_settings.json)"

# Get Endpoints
aws timestream-query describe-endpoints \
    --query 'Endpoints' --output json | tee endpoints.json
echo "Described Endpoints: $(cat endpoints.json)"

# List Tags for Resource
aws timestream-query list-tags-for-resource \
    --resource-arn "${SCHEDULED_QUERY_ARN}" \
    --query 'Tags' --output json | tee tags_for_resource.json
echo "Listed Tags for Resource: $(cat tags_for_resource.json)"

# Clean up
aws timestream-query delete-scheduled-query \
    --scheduled-query-arn "${SCHEDULED_QUERY_ARN}" || true
echo "Deleted Scheduled Query: ${SCHEDULED_QUERY_ARN}"

echo "PASS"