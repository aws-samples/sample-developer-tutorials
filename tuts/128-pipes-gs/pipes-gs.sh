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
QUEUE_URL=$(aws sqs create-queue --queue-name "pipe-queue-$SUFFIX" --query 'QueueUrl' --output text)
echo "Queue: $QUEUE_URL"
CREATED_RESOURCES+=("queue:$QUEUE_URL")
echo "=== Creating Log Group ==="
aws logs create-log-group --log-group-name "/aws/pipes/pipe-$SUFFIX"
CREATED_RESOURCES+=("loggroup:/aws/pipes/pipe-$SUFFIX")
echo "=== Listing Pipes ==="
aws pipes list-pipes --query 'Pipes[].Name' --output text || echo "No pipes"
echo "=== Tutorial Complete ==="
