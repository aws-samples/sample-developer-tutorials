#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); F="dlq-func-${RANDOM_ID}"; R="dlq-func-role-${RANDOM_ID}"; Q="dlq-func-q-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo "Cleaning up..."; aws lambda delete-function --function-name "$F" 2>/dev/null; [ -n "$QU" ] && aws sqs delete-queue --queue-url "$QU" 2>/dev/null; aws iam detach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole 2>/dev/null; aws iam detach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess 2>/dev/null; aws iam delete-role --role-name "$R" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
RA=$(aws iam create-role --role-name "$R" --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text)
aws iam attach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name "$R" --policy-arn arn:aws:iam::aws:policy/AmazonSQSFullAccess; sleep 10
QU=$(aws sqs create-queue --queue-name "$Q" --query QueueUrl --output text)
QA=$(aws sqs get-queue-attributes --queue-url "$QU" --attribute-names QueueArn --query Attributes.QueueArn --output text)
echo "Step 1: Creating function that always fails"
echo "def handler(e,c): raise Exception('Intentional failure')" > "$WORK_DIR/i.py"
(cd "$WORK_DIR" && zip f.zip i.py > /dev/null)
aws lambda create-function --function-name "$F" --zip-file "fileb://$WORK_DIR/f.zip" --handler i.handler --runtime python3.12 --role "$RA" --dead-letter-config "{\"TargetArn\":\"$QA\"}" --architectures x86_64 > /dev/null
aws lambda wait function-active-v2 --function-name "$F"
echo "  Function with DLQ configured"
echo "Step 2: Invoking async (will fail and go to DLQ)"
aws lambda invoke --function-name "$F" --invocation-type Event --cli-binary-format raw-in-base64-out --payload '{}' "$WORK_DIR/out.json" > /dev/null
echo "  Invoked async — Lambda will retry twice then send to DLQ"
echo "Step 3: Checking DLQ (after retries, ~3 min)"
echo "  DLQ messages: $(aws sqs get-queue-attributes --queue-url "$QU" --attribute-names ApproximateNumberOfMessages --query Attributes.ApproximateNumberOfMessages --output text)"
echo "  (Message will appear after Lambda exhausts retries)"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
