#!/bin/bash
# Tutorial: Create and run a Step Functions state machine
# Source: https://docs.aws.amazon.com/step-functions/latest/dg/getting-started-with-sfn.html

WORK_DIR=$(mktemp -d)
LOG_FILE="$WORK_DIR/stepfunctions-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null)}}
if [ -z "$REGION" ]; then
    echo "ERROR: No AWS region configured. Set one with: export AWS_DEFAULT_REGION=us-east-1"
    exit 1
fi
export AWS_DEFAULT_REGION="$REGION"
echo "Region: $REGION"

RANDOM_ID=$(openssl rand -hex 4)
SM_NAME="tut-state-machine-${RANDOM_ID}"
ROLE_NAME="sfn-tut-role-${RANDOM_ID}"

handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }
trap 'handle_error $LINENO' ERR

cleanup() {
    echo ""
    echo "Cleaning up resources..."
    [ -n "$SM_ARN" ] && aws stepfunctions delete-state-machine --state-machine-arn "$SM_ARN" 2>/dev/null && \
        echo "  Deleted state machine $SM_NAME"
    aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name sfn-logs 2>/dev/null
    aws iam delete-role --role-name "$ROLE_NAME" 2>/dev/null && echo "  Deleted role $ROLE_NAME"
    rm -rf "$WORK_DIR"
    echo "Cleanup complete."
}

# Step 1: Create IAM role
echo "Step 1: Creating IAM role: $ROLE_NAME"
ROLE_ARN=$(aws iam create-role --role-name "$ROLE_NAME" \
    --assume-role-policy-document '{
        "Version":"2012-10-17",
        "Statement":[{"Effect":"Allow","Principal":{"Service":"states.amazonaws.com"},"Action":"sts:AssumeRole"}]
    }' --query 'Role.Arn' --output text)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name sfn-logs \
    --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:*"],"Resource":"*"}]}'
echo "  Role ARN: $ROLE_ARN"
sleep 10

# Step 2: Create state machine
echo "Step 2: Creating state machine: $SM_NAME"
cat > "$WORK_DIR/definition.json" << 'EOF'
{
  "Comment": "A Hello World state machine",
  "StartAt": "Greeting",
  "States": {
    "Greeting": {
      "Type": "Pass",
      "Result": {"message": "Hello from Step Functions!"},
      "Next": "WaitStep"
    },
    "WaitStep": {
      "Type": "Wait",
      "Seconds": 2,
      "Next": "ChoiceStep"
    },
    "ChoiceStep": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.message",
          "StringEquals": "Hello from Step Functions!",
          "Next": "SuccessStep"
        }
      ],
      "Default": "FailStep"
    },
    "SuccessStep": {
      "Type": "Succeed"
    },
    "FailStep": {
      "Type": "Fail",
      "Error": "UnexpectedMessage",
      "Cause": "Message did not match expected value"
    }
  }
}
EOF

SM_ARN=$(aws stepfunctions create-state-machine \
    --name "$SM_NAME" \
    --definition "file://$WORK_DIR/definition.json" \
    --role-arn "$ROLE_ARN" \
    --query 'stateMachineArn' --output text)
echo "  State machine ARN: $SM_ARN"

# Step 3: Start an execution
echo "Step 3: Starting execution"
EXEC_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn "$SM_ARN" \
    --input '{"key": "value"}' \
    --query 'executionArn' --output text)
echo "  Execution ARN: $EXEC_ARN"

# Step 4: Wait for execution to complete
echo "Step 4: Waiting for execution to complete..."
for i in $(seq 1 15); do
    STATUS=$(aws stepfunctions describe-execution --execution-arn "$EXEC_ARN" \
        --query 'status' --output text)
    echo "  Status: $STATUS"
    [ "$STATUS" = "SUCCEEDED" ] || [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "TIMED_OUT" ] && break
    sleep 3
done

# Step 5: Get execution results
echo "Step 5: Execution results"
aws stepfunctions describe-execution --execution-arn "$EXEC_ARN" \
    --query '{Status:status,Input:input,Output:output,Started:startDate,Stopped:stopDate}' --output table

# Step 6: Get execution history
echo "Step 6: Execution history (key events)"
aws stepfunctions get-execution-history --execution-arn "$EXEC_ARN" \
    --query 'events[?type!=`TaskStateEntered` && type!=`TaskStateExited`].{Id:id,Type:type}' --output table | head -20

echo ""
echo "Tutorial complete."
echo "Do you want to clean up all resources? (y/n): "
read -r CHOICE
if [[ "$CHOICE" =~ ^[Yy]$ ]]; then
    cleanup
else
    echo "Manual cleanup:"
    echo "  aws stepfunctions delete-state-machine --state-machine-arn $SM_ARN"
    echo "  aws iam delete-role-policy --role-name $ROLE_NAME --policy-name sfn-logs"
    echo "  aws iam delete-role --role-name $ROLE_NAME"
fi
