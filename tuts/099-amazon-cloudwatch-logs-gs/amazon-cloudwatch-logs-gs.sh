#!/bin/bash
# Tutorial: Create log groups, streams, and query logs with CloudWatch Logs
# Source: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/cwlogs-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
LOG_GROUP="/tutorial/app-${RANDOM_ID}"
STREAM_NAME="web-server"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws logs delete-log-group --log-group-name "$LOG_GROUP" 2>/dev/null && \
        echo "  Deleted log group $LOG_GROUP"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a log group
echo "Step 1: Creating log group: $LOG_GROUP"
aws logs create-log-group --log-group-name "$LOG_GROUP"
echo "  Log group created"

# Step 2: Set retention policy
echo "Step 2: Setting retention to 7 days"
aws logs put-retention-policy --log-group-name "$LOG_GROUP" --retention-in-days 7
aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" \
    --query 'logGroups[0].{Name:logGroupName,Retention:retentionInDays}' --output table

# Step 3: Create a log stream
echo "Step 3: Creating log stream: $STREAM_NAME"
aws logs create-log-stream --log-group-name "$LOG_GROUP" --log-stream-name "$STREAM_NAME"

# Step 4: Put log events
echo "Step 4: Writing log events"
NOW_MS=$(($(date +%s) * 1000))
aws logs put-log-events --log-group-name "$LOG_GROUP" --log-stream-name "$STREAM_NAME" \
    --log-events \
    "[{\"timestamp\":$NOW_MS,\"message\":\"INFO: Application started on port 8080\"},{\"timestamp\":$((NOW_MS+1000)),\"message\":\"INFO: Connected to database\"},{\"timestamp\":$((NOW_MS+2000)),\"message\":\"WARN: Slow query detected (1200ms)\"},{\"timestamp\":$((NOW_MS+3000)),\"message\":\"ERROR: Connection timeout to upstream service\"},{\"timestamp\":$((NOW_MS+4000)),\"message\":\"INFO: Request processed in 45ms\"}]" \
    > /dev/null
echo "  Wrote 5 log events"

# Step 5: Get log events
echo "Step 5: Retrieving log events"
sleep 2
aws logs get-log-events --log-group-name "$LOG_GROUP" --log-stream-name "$STREAM_NAME" \
    --query 'events[].{Time:timestamp,Message:message}' --output table

# Step 6: Filter log events
echo "Step 6: Filtering for ERROR and WARN messages"
aws logs filter-log-events --log-group-name "$LOG_GROUP" \
    --filter-pattern "?ERROR ?WARN" \
    --query 'events[].{Message:message}' --output table

# Step 7: Run a Logs Insights query
echo "Step 7: Running Logs Insights query"
QUERY_ID=$(aws logs start-query \
    --log-group-name "$LOG_GROUP" \
    --start-time $(($(date +%s) - 300)) \
    --end-time $(date +%s) \
    --query-string 'fields @timestamp, @message | filter @message like /ERROR|WARN/ | sort @timestamp desc' \
    --query 'queryId' --output text)
echo "  Query ID: $QUERY_ID"
sleep 3
aws logs get-query-results --query-id "$QUERY_ID" \
    --query '{Status:status,Results:results[].{message:@[?field==`@message`].value|[0]}}' --output table

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws logs delete-log-group --log-group-name $LOG_GROUP"
fi
