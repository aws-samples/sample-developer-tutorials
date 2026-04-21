#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/lambda-env.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); FUNC="tut-env-${RANDOM_ID}"; ROLE="lambda-env-role-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws lambda delete-function --function-name "$FUNC" 2>/dev/null && echo "  Deleted function"; aws iam detach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam delete-role --role-name "$ROLE" 2>/dev/null && echo "  Deleted role"; rm -rf "$WORK_DIR"; echo "Done."; }
ROLE_ARN=$(aws iam create-role --role-name "$ROLE" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query 'Role.Arn' --output text)
aws iam attach-role-policy --role-name "$ROLE" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole; sleep 10
echo "Step 1: Creating function with environment variables"
cat > "$WORK_DIR/index.py" << 'EOF'
import os
def handler(event, context):
    return {k: os.environ.get(k, 'not set') for k in ['APP_ENV', 'DB_HOST', 'LOG_LEVEL', 'FEATURE_FLAG']}
EOF
(cd "$WORK_DIR" && zip func.zip index.py > /dev/null)
aws lambda create-function --function-name "$FUNC" --zip-file "fileb://$WORK_DIR/func.zip" --handler index.handler --runtime python3.12 --role "$ROLE_ARN" --environment 'Variables={APP_ENV=production,DB_HOST=db.example.com,LOG_LEVEL=INFO,FEATURE_FLAG=enabled}' --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$FUNC"
echo "Step 2: Invoking function"
aws lambda invoke --function-name "$FUNC" --cli-binary-format raw-in-base64-out "$WORK_DIR/out.json" > /dev/null
cat "$WORK_DIR/out.json" | python3 -m json.tool
echo "Step 3: Updating environment variables"
aws lambda update-function-configuration --function-name "$FUNC" --environment 'Variables={APP_ENV=staging,DB_HOST=staging-db.example.com,LOG_LEVEL=DEBUG,FEATURE_FLAG=disabled}' --query 'Environment.Variables' --output table > /dev/null
aws lambda wait function-updated-v2 --function-name "$FUNC"
echo "Step 4: Invoking with updated vars"
aws lambda invoke --function-name "$FUNC" --cli-binary-format raw-in-base64-out "$WORK_DIR/out2.json" > /dev/null
cat "$WORK_DIR/out2.json" | python3 -m json.tool
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
