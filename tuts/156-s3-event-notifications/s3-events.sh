#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/s3-events.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text); echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); BUCKET="s3-events-tut-${RANDOM_ID}-${ACCOUNT}"; QUEUE="s3-events-tut-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws s3 rm "s3://$BUCKET" --recursive --quiet 2>/dev/null; aws s3 rb "s3://$BUCKET" 2>/dev/null && echo "  Deleted bucket"; [ -n "$QUEUE_URL" ] && aws sqs delete-queue --queue-url "$QUEUE_URL" 2>/dev/null && echo "  Deleted queue"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating SQS queue for notifications"
QUEUE_URL=$(aws sqs create-queue --queue-name "$QUEUE" --query 'QueueUrl' --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
aws sqs set-queue-attributes --queue-url "$QUEUE_URL" --attributes "{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":{\\\"Service\\\":\\\"s3.amazonaws.com\\\"},\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$QUEUE_ARN\\\"}]}\"}"
echo "  Queue: $QUEUE_URL"
echo "Step 2: Creating bucket with event notification"
if [ "$REGION" = "us-east-1" ]; then aws s3api create-bucket --bucket "$BUCKET" > /dev/null; else aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint="$REGION" > /dev/null; fi
aws s3api put-bucket-notification-configuration --bucket "$BUCKET" --notification-configuration "{\"QueueConfigurations\":[{\"QueueArn\":\"$QUEUE_ARN\",\"Events\":[\"s3:ObjectCreated:*\"]}]}"
echo "  Notifications configured"
echo "Step 3: Uploading a file to trigger notification"
echo "test data" > "$WORK_DIR/test.txt"
aws s3 cp "$WORK_DIR/test.txt" "s3://$BUCKET/test.txt" --quiet
sleep 5
echo "Step 4: Reading notification from SQS"
aws sqs receive-message --queue-url "$QUEUE_URL" --max-number-of-messages 1 --wait-time-seconds 10 --query 'Messages[0].Body' --output text 2>/dev/null | python3 -c "import sys,json;d=json.loads(sys.stdin.read());r=d.get('Records',[{}])[0];print(f\"  Event: {r.get('eventName','?')}\\n  Bucket: {r.get('s3',{}).get('bucket',{}).get('name','?')}\\n  Key: {r.get('s3',{}).get('object',{}).get('key','?')}\")" 2>/dev/null || echo "  No notification yet"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
