#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/conc.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); FUNC="tut-conc-${RANDOM_ID}"; ROLE="lambda-conc-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws lambda delete-function-concurrency --function-name "$FUNC" 2>/dev/null; aws lambda delete-function --function-name "$FUNC" 2>/dev/null && echo "  Deleted function"; aws iam detach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam delete-role --role-name "$ROLE" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
ROLE_ARN=$(aws iam create-role --role-name "$ROLE" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole; sleep 10
cat > "$WORK_DIR/index.py" << 'EOF'
import time
def handler(event, context):
    time.sleep(1)
    return {"remaining_ms": context.get_remaining_time_in_millis()}
EOF
(cd "$WORK_DIR" && zip func.zip index.py > /dev/null)
aws lambda create-function --function-name "$FUNC" --zip-file "fileb://$WORK_DIR/func.zip" --handler index.handler --runtime python3.12 --role "$ROLE_ARN" --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$FUNC"
echo "Step 1: Getting account concurrency limits"
aws lambda get-account-settings --query 'AccountLimit.{Total:TotalCodeSize,Concurrent:ConcurrentExecutions,Unreserved:UnreservedConcurrentExecutions}' --output table
echo "Step 2: Setting reserved concurrency"
aws lambda put-function-concurrency --function-name "$FUNC" --reserved-concurrent-executions 5 --query 'ReservedConcurrentExecutions' --output text > /dev/null
echo "  Reserved: 5 concurrent executions"
echo "Step 3: Getting function concurrency"
aws lambda get-function-concurrency --function-name "$FUNC" --query 'ReservedConcurrentExecutions' --output text
echo "Step 4: Removing reserved concurrency"
aws lambda delete-function-concurrency --function-name "$FUNC"
echo "  Reserved concurrency removed"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
