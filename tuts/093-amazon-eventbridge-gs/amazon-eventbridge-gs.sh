#!/bin/bash
# Tutorial: Create an EventBridge rule that triggers a Lambda function
# Source: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-get-started.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/eventbridge-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
RULE_NAME="eb-tut-rule-${RANDOM_ID}"
FUNCTION_NAME="eb-tut-handler-${RANDOM_ID}"
ROLE_NAME="eb-tut-role-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    aws events remove-targets --rule "$RULE_NAME" --ids lambda-target > /dev/null 2>&1 && echo "  Removed rule target"
    aws events delete-rule --name "$RULE_NAME" 2>/dev/null && echo "  Deleted rule $RULE_NAME"
    aws lambda delete-function --function-name "$FUNCTION_NAME" 2>/dev/null && echo "  Deleted function $FUNCTION_NAME"
    aws iam detach-role-policy --role-name "$ROLE_NAME" \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
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
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
echo "  Role ARN: $ROLE_ARN"
echo "  Waiting for role propagation..."
sleep 10

# Step 2: Create Lambda function
echo "Step 2: Creating Lambda function: $FUNCTION_NAME"
cat > "$WORK_DIR/index.mjs" << 'EOF'
export const handler = async (event) => {
    console.log('EventBridge event received:', JSON.stringify(event, null, 2));
    return { statusCode: 200, body: 'Event processed' };
};
EOF
(cd "$WORK_DIR" && zip function.zip index.mjs > /dev/null)

aws lambda create-function --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$WORK_DIR/function.zip" \
    --handler index.handler --runtime nodejs22.x \
    --role "$ROLE_ARN" --timeout 30 \
    --architectures x86_64 \
    --query 'FunctionArn' --output text
aws lambda wait function-active-v2 --function-name "$FUNCTION_NAME"
FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.FunctionArn' --output text)

# Step 3: Create EventBridge rule (runs every minute)
echo "Step 3: Creating EventBridge rule: $RULE_NAME (every 1 minute)"
RULE_ARN=$(aws events put-rule --name "$RULE_NAME" \
    --schedule-expression "rate(1 minute)" \
    --state ENABLED \
    --query 'RuleArn' --output text)
echo "  Rule ARN: $RULE_ARN"

# Step 4: Grant EventBridge permission to invoke Lambda
echo "Step 4: Granting EventBridge permission to invoke Lambda"
aws lambda add-permission --function-name "$FUNCTION_NAME" \
    --statement-id eb-invoke --action lambda:InvokeFunction \
    --principal events.amazonaws.com --source-arn "$RULE_ARN" > /dev/null

# Step 5: Add Lambda as target
echo "Step 5: Adding Lambda as rule target"
aws events put-targets --rule "$RULE_NAME" \
    --targets "Id=lambda-target,Arn=$FUNCTION_ARN" > /dev/null
echo "  Target added"

# Step 6: Wait for the rule to fire and check logs
echo "Step 6: Waiting for EventBridge to trigger Lambda (~60s)..."
sleep 65

LOG_GROUP="/aws/lambda/$FUNCTION_NAME"
FOUND_LOGS=false
for i in $(seq 1 10); do
    LOG_STREAM=$(aws logs describe-log-streams --log-group-name "$LOG_GROUP" \
        --order-by LastEventTime --descending --limit 1 \
        --query 'logStreams[0].logStreamName' --output text 2>/dev/null || true)
    if [ -n "$LOG_STREAM" ] && [ "$LOG_STREAM" != "None" ]; then
        echo "  Log stream: $LOG_STREAM"
        echo "  Recent events:"
        aws logs get-log-events --log-group-name "$LOG_GROUP" \
            --log-stream-name "$LOG_STREAM" --limit 5 \
            --query 'events[].message' --output text
        FOUND_LOGS=true
        break
    fi
    sleep 5
done
if [ "$FOUND_LOGS" = false ]; then
    echo "  Logs not available yet — the rule may not have fired yet"
fi

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Resources left running. The rule fires every minute."
    echo "Manual cleanup:"
    echo "  aws events remove-targets --rule $RULE_NAME --ids lambda-target"
    echo "  aws events delete-rule --name $RULE_NAME"
    echo "  aws lambda delete-function --function-name $FUNCTION_NAME"
    echo "  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
