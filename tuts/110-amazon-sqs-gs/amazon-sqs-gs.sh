#!/bin/bash
# Tutorial: Create queues and send messages with Amazon SQS
# Source: https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-getting-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/sqs-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
QUEUE_NAME="tut-queue-${RANDOM_ID}"
DLQ_NAME="tut-dlq-${RANDOM_ID}"
FIFO_NAME="tut-fifo-${RANDOM_ID}.fifo"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$QUEUE_URL" ] && aws sqs delete-queue --queue-url "$QUEUE_URL" 2>/dev/null && echo "  Deleted $QUEUE_NAME"
    [ -n "$DLQ_URL" ] && aws sqs delete-queue --queue-url "$DLQ_URL" 2>/dev/null && echo "  Deleted $DLQ_NAME"
    [ -n "$FIFO_URL" ] && aws sqs delete-queue --queue-url "$FIFO_URL" 2>/dev/null && echo "  Deleted $FIFO_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create a standard queue
echo "Step 1: Creating standard queue: $QUEUE_NAME"
QUEUE_URL=$(aws sqs create-queue --queue-name "$QUEUE_NAME" \
    --attributes '{"VisibilityTimeout":"30","MessageRetentionPeriod":"86400"}' \
    --query 'QueueUrl' --output text)
echo "  URL: $QUEUE_URL"

# Step 2: Create a dead-letter queue
echo "Step 2: Creating dead-letter queue: $DLQ_NAME"
DLQ_URL=$(aws sqs create-queue --queue-name "$DLQ_NAME" --query 'QueueUrl' --output text)
DLQ_ARN=$(aws sqs get-queue-attributes --queue-url "$DLQ_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

# Configure redrive policy
aws sqs set-queue-attributes --queue-url "$QUEUE_URL" \
    --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQ_ARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
echo "  DLQ configured (max receives: 3)"

# Step 3: Send messages
echo "Step 3: Sending messages"
aws sqs send-message --queue-url "$QUEUE_URL" --message-body "Hello from SQS tutorial" > /dev/null
aws sqs send-message --queue-url "$QUEUE_URL" --message-body "Message with attributes" \
    --message-attributes '{"Author":{"DataType":"String","StringValue":"Tutorial"}}' > /dev/null
aws sqs send-message-batch --queue-url "$QUEUE_URL" --entries \
    '[{"Id":"m1","MessageBody":"Batch message 1"},{"Id":"m2","MessageBody":"Batch message 2"},{"Id":"m3","MessageBody":"Batch message 3"}]' > /dev/null
echo "  Sent 5 messages (2 individual + 3 batch)"

# Step 4: Receive and process messages
echo "Step 4: Receiving messages"
MSGS=$(aws sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 5 \
    --message-attribute-names All --attribute-names All)
echo "$MSGS" | python3 -c "
import sys,json
msgs=json.load(sys.stdin).get('Messages',[])
for m in msgs:
    print(f'  Body: {m[\"Body\"]}')
    attrs=m.get('MessageAttributes',{})
    for k,v in attrs.items():
        print(f'  Attribute: {k}={v[\"StringValue\"]}')
print(f'  Received {len(msgs)} messages')
"

# Step 5: Delete processed messages
echo "Step 5: Deleting processed messages"
echo "$MSGS" | python3 -c "
import sys,json,subprocess
msgs=json.load(sys.stdin).get('Messages',[])
for m in msgs:
    subprocess.run(['aws','sqs','delete-message','--queue-url','$QUEUE_URL','--receipt-handle',m['ReceiptHandle']],capture_output=True)
print(f'  Deleted {len(msgs)} messages')
"

# Step 6: Check queue attributes
echo "Step 6: Queue attributes"
aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names All \
    --query 'Attributes.{Messages:ApproximateNumberOfMessages,Visibility:VisibilityTimeout,Retention:MessageRetentionPeriod,DLQ:RedrivePolicy}' --output table

# Step 7: Create a FIFO queue
echo "Step 7: Creating FIFO queue: $FIFO_NAME"
FIFO_URL=$(aws sqs create-queue --queue-name "$FIFO_NAME" \
    --attributes '{"FifoQueue":"true","ContentBasedDeduplication":"true"}' \
    --query 'QueueUrl' --output text)
aws sqs send-message --queue-url "$FIFO_URL" --message-body "FIFO message" \
    --message-group-id "tutorial" > /dev/null
echo "  FIFO message sent with content-based deduplication"

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws sqs delete-queue --queue-url $QUEUE_URL"
    echo "  aws sqs delete-queue --queue-url $DLQ_URL"
    echo "  aws sqs delete-queue --queue-url $FIFO_URL"
fi
