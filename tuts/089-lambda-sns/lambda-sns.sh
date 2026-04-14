#!/bin/bash
# Tutorial: Using an AWS Lambda function as a subscriber to an Amazon SNS topic
# Source: https://docs.aws.amazon.com/lambda/latest/dg/with-sns-example.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/lambda-sns-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
TOPIC_NAME="sns-lambda-tut-${RANDOM_ID}"
ROLE_NAME="lambda-sns-role-${RANDOM_ID}"
FUNCTION_NAME="sns-processor-${RANDOM_ID}"

RESOURCES=()
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$SUBSCRIPTION_ARN" ] && [ "$SUBSCRIPTION_ARN" != "pending confirmation" ] && \
        aws sns unsubscribe --subscription-arn "$SUBSCRIPTION_ARN" 2>/dev/null && echo "  Deleted subscription"
    aws lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null && echo "  Deleted function $FUNCTION_NAME"
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    aws sns delete-topic --topic-arn "$TOPIC_ARN" 2>/dev/null && echo "  Deleted topic $TOPIC_NAME"
    aws logs delete-log-group --log-group-name "/aws/lambda/$FUNCTION_NAME" 2>/dev/null && echo "  Deleted log group"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create SNS topic
echo "Step 1: Creating SNS topic: $TOPIC_NAME"
TOPIC_ARN=$(aws sns create-topic --name "$TOPIC_NAME" --query 'TopicArn' --output text)
echo "  Topic ARN: $TOPIC_ARN"

# Step 2: Create IAM role
echo "Step 2: Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
echo "  Role ARN: $ROLE_ARN"
echo "  Waiting for role propagation..."
sleep 10

# Step 3: Create Lambda function
echo "Step 3: Creating Lambda function: $FUNCTION_NAME"
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => {
    for (const record of event.Records) {
        console.log(`Processed message: ${record.Sns.Message}`);
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

# Step 4: Subscribe Lambda to SNS
echo "Step 4: Subscribing Lambda to SNS topic"
FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.FunctionArn' --output text)

aws lambda add-permission --function-name "$FUNCTION_NAME" \
    --statement-id sns-invoke --action lambda:InvokeFunction \
    --principal sns.amazonaws.com --source-arn "$TOPIC_ARN" > /dev/null

SUBSCRIPTION_ARN=$(aws sns subscribe --protocol lambda \
    --topic-arn "$TOPIC_ARN" --notification-endpoint "$FUNCTION_ARN" \
    --query 'SubscriptionArn' --output text)
echo "  Subscription ARN: $SUBSCRIPTION_ARN"

# Step 5: Publish a test message
echo "Step 5: Publishing test message"
MESSAGE_ID=$(aws sns publish --topic-arn "$TOPIC_ARN" \
    --message "Hello from the Lambda-SNS tutorial" --subject "Test" \
    --query 'MessageId' --output text)
echo "  Message ID: $MESSAGE_ID"

# Step 6: Verify in CloudWatch Logs
echo "Step 6: Verifying Lambda processed the message"
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
    echo "  aws sns unsubscribe --subscription-arn $SUBSCRIPTION_ARN"
    echo "  aws lambda delete-function --function-name $FUNCTION_NAME"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
    echo "  aws sns delete-topic --topic-arn $TOPIC_ARN"
fi
