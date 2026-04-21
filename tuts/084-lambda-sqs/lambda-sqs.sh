#!/bin/bash
# Tutorial: Using Lambda with Amazon SQS
# Source: https://docs.aws.amazon.com/lambda/latest/dg/with-sqs-example.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/lambda-sqs-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
ROLE_NAME="lambda-sqs-role-${RANDOM_ID}"
FUNCTION_NAME="sqs-processor-${RANDOM_ID}"
QUEUE_NAME="lambda-tut-queue-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$EVENT_SOURCE_UUID" ] && \
        aws lambda delete-event-source-mapping --uuid "$EVENT_SOURCE_UUID" 2>/dev/null && echo "  Deleted event source mapping"
    aws lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null && echo "  Deleted function $FUNCTION_NAME"
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    [ -n "$QUEUE_URL" ] && aws sqs delete-queue --queue-url "$QUEUE_URL" 2>/dev/null && echo "  Deleted queue $QUEUE_NAME"
    aws logs delete-log-group --log-group-name "/aws/lambda/$FUNCTION_NAME" 2>/dev/null && echo "  Deleted log group"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create IAM role
echo "Step 1: Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole
echo "  Role ARN: $ROLE_ARN"
echo "  Waiting for role propagation..."
sleep 10

# Step 2: Create Lambda function
echo "Step 2: Creating Lambda function: $FUNCTION_NAME"
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => {
    for (const message of event.Records) {
        console.log(`Processed message: ${message.body}`);
    }
    return { statusCode: 200 };
};
EOF
(cd "$WORK_DIR" && zip function.zip index.mjs > /dev/null)

aws lambda create-function --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$WORK_DIR/function.zip" \
    --handler index.handler --runtime nodejs22.x \
    --role "$ROLE_ARN" --timeout 30 \
    --architectures x86_64 \
    --query 'FunctionArn' --output text

echo "  Waiting for function to become active..."
aws lambda wait function-active-v2 --function-name "$FUNCTION_NAME"

# Step 3: Test the function with a sample SQS event
echo "Step 3: Testing Lambda with sample SQS event"
cat > "$WORK_DIR/test-event.json" << EOF
{
    "Records": [{
        "messageId": "test-msg-001",
        "body": "Hello from SQS test event",
        "attributes": {"ApproximateReceiveCount": "1", "SentTimestamp": "1545082649183"},
        "messageAttributes": {},
        "md5OfBody": "098f6bcd4621d373cade4e832627b4f6",
        "eventSource": "aws:sqs",
        "eventSourceARN": "arn:aws:sqs:$REGION:000000000000:test-queue",
        "awsRegion": "$REGION"
    }]
}
EOF

aws lambda invoke --function-name "$FUNCTION_NAME" \
    --payload "fileb://$WORK_DIR/test-event.json" \
    --cli-binary-format raw-in-base64-out \
    "$WORK_DIR/response.json" > /dev/null
echo "  Response: $(cat "$WORK_DIR/response.json")"

# Step 4: Create SQS queue
echo "Step 4: Creating SQS queue: $QUEUE_NAME"
QUEUE_URL=$(aws sqs create-queue --queue-name "$QUEUE_NAME" --query 'QueueUrl' --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" \
    --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
echo "  Queue ARN: $QUEUE_ARN"

# Step 5: Create event source mapping
echo "Step 5: Connecting SQS queue to Lambda"
EVENT_SOURCE_UUID=$(aws lambda create-event-source-mapping \
    --function-name "$FUNCTION_NAME" \
    --batch-size 10 \
    --event-source-arn "$QUEUE_ARN" \
    --query 'UUID' --output text)
echo "  Event source mapping: $EVENT_SOURCE_UUID"

# Step 6: Send test messages via SQS
echo "Step 6: Sending test messages to SQS"
aws sqs send-message --queue-url "$QUEUE_URL" --message-body "Hello from the Lambda-SQS tutorial" > /dev/null
aws sqs send-message --queue-url "$QUEUE_URL" --message-body "This is message number 2" > /dev/null
echo "  Sent 2 messages. Waiting for Lambda to process them..."
sleep 15

# Step 7: Verify in CloudWatch Logs
echo "Step 7: Verifying Lambda processed the messages"
LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
FOUND_LOGS=false
for i in $(seq 1 15); do
    LOG_STREAM=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" \
        --order-by LastEventTime --descending --limit 1 \
        --query 'logStreams[0].logStreamName' --output text 2>/dev/null || true)
    if [ -n "$LOG_STREAM" ] && [ "$LOG_STREAM" != "None" ]; then
        echo "  Log stream: $LOG_STREAM"
        aws logs get-log-events --log-group-name "$LOG_GROUP" \
            --log-stream-name "$LOG_STREAM" \
            --query 'events[].message' --output text
        FOUND_LOGS=true
        break
    fi
    sleep 5
done
if [ "$FOUND_LOGS" = false ]; then
    echo "  Logs not available yet (this is normal — they can take a minute to appear)"
fi

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. Manual cleanup commands:"
    echo "  aws lambda delete-event-source-mapping --uuid $EVENT_SOURCE_UUID"
    echo "  aws lambda delete-function --function-name $FUNCTION_NAME"
    echo "  aws sqs delete-queue --queue-url $QUEUE_URL"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
