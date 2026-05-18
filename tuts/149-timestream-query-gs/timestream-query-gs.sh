#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
LOG_FILE="${TEMP_DIR}/script.log"
CREATED_RESOURCES=()

cleanup_resources() {
    for ARN in "${CREATED_RESOURCES[@]}"; do
        aws timestream-query delete-scheduled-query --scheduled-query-arn "${ARN}" || true
    done
    rm -rf "${TEMP_DIR}"
}
trap cleanup_resources EXIT

# Step 1: Create Scheduled Query
SCHEDULED_QUERY_NAME="scheduled-query-${SUFFIX}"
QUERY_STRING="SELECT * FROM your_table WHERE time > ago(5m)"
SCHEDULE_CONFIGURATION='{"ScheduleExpression": "cron(0/5 * * *? *)"}'
NOTIFICATION_CONFIGURATION='{"SnsConfiguration": {"TopicArn": "arn:aws:sns:us-east-1:123456789012:your-sns-topic"}}'

SCHEDULED_QUERY_ARN=$(aws timestream-query create-scheduled-query \
    --name "${SCHEDULED_QUERY_NAME}" \
    --query-string "${QUERY_STRING}" \
    --schedule-configuration "${SCHEDULE_CONFIGURATION}" \
    --notification-configuration "${NOTIFICATION_CONFIGURATION}" \
    --query 'ScheduledQueryArn' --output text)
aws timestream-query tag-resource --resource-arn "${SCHEDULED_QUERY_ARN}" --tags Key=project,Value=doc-smith Key=tutorial,Value=timestream-query-gs
CREATED_RESOURCES+=("${SCHEDULED_QUERY_ARN}")
echo "Created Scheduled Query: ${SCHEDULED_QUERY_ARN}" >> "${LOG_FILE}"

# Step 2: Verify Scheduled Query
aws timestream-query describe-scheduled-query \
    --scheduled-query-arn "${SCHEDULED_QUERY_ARN}" \
    --query 'ScheduledQuery' --output json >> "${LOG_FILE}"
echo "Described Scheduled Query" >> "${LOG_FILE}"

# Step 3: List Scheduled Queries
aws timestream-query list-scheduled-queries \
    --query 'ScheduledQueries' --output json >> "${LOG_FILE}"
echo "Listed Scheduled Queries" >> "${LOG_FILE}"

# Step 4: Get Account Settings
aws timestream-query describe-account-settings \
    --query 'AccountSettings' --output json >> "${LOG_FILE}"
echo "Described Account Settings" >> "${LOG_FILE}"

# Step 5: Get Endpoints
aws timestream-query describe-endpoints \
    --query 'Endpoints' --output json >> "${LOG_FILE}"
echo "Described Endpoints" >> "${LOG_FILE}"

# Step 6: List Tags for Resource
aws timestream-query list-tags-for-resource \
    --resource-arn "${SCHEDULED_QUERY_ARN}" \
    --query 'Tags' --output json >> "${LOG_FILE}"
echo "Listed Tags for Resource" >> "${LOG_FILE}"

echo "PASS" >> "${LOG_FILE}"
