#!/bin/bash
set -e
SUFFIX=$(head -c 20 /dev/urandom | base64 | tr -dc a-z0-9 | head -c 8 || true)
TEMP_DIR=$(mktemp -d)
declare -a CREATED_RESOURCES=()
cleanup_resources() {
    for ((i=${#CREATED_RESOURCES[@]}-1; i>=0; i--)); do
        IFS=: read -r type id <<< "${CREATED_RESOURCES[$i]}"
        case $type in
            queue) aws sqs delete-queue --queue-url "$id" 2>/dev/null || true ;;
            loggroup) aws logs delete-log-group --log-group-name "$id" 2>/dev/null || true ;;
        esac
    done
    rm -rf "$TEMP_DIR"
}
trap cleanup_resources EXIT
echo "=== Creating SQS Queue ==="
QUEUE_URL=$(aws sqs create-queue --tags '{"project":"doc-smith","tutorial":"pipes-gs"}' --queue-name "pipe-queue-$SUFFIX" --query 'QueueUrl' --output text)
echo "Queue: $QUEUE_URL"
CREATED_RESOURCES+=("queue:$QUEUE_URL")
echo "=== Creating Log Group ==="
LOG_GROUP_NAME="/aws/pipes/pipe-$SUFFIX"
aws logs create-log-group --log-group-name "$LOG_GROUP_NAME"
aws logs tag-resource --resource-arn "arn:aws:logs:us-east-1:559823168634:log-group:$LOG_GROUP_NAME" --tags '{"project":"doc-smith","tutorial":"pipes-gs"}'
CREATED_RESOURCES+=("loggroup:$LOG_GROUP_NAME")
echo "=== Listing Pipes ==="
aws pipes list-pipes --query 'Pipes[].Name' --output text || echo "No pipes"
echo "=== Tutorial Complete ==="
