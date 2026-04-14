#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/tut.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); Q="dlq-tut-${RANDOM_ID}"; DLQ="dlq-dead-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo "Cleaning up..."; [ -n "$QU" ] && aws sqs delete-queue --queue-url "$QU" 2>/dev/null; [ -n "$DU" ] && aws sqs delete-queue --queue-url "$DU" 2>/dev/null; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating DLQ"
DU=$(aws sqs create-queue --queue-name "$DLQ" --query QueueUrl --output text)
DA=$(aws sqs get-queue-attributes --queue-url "$DU" --attribute-names QueueArn --query Attributes.QueueArn --output text)
echo "Step 2: Creating main queue with redrive"
QU=$(aws sqs create-queue --queue-name "$Q" --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DA\\\",\\\"maxReceiveCount\\\":\\\"2\\\"}\"}" --query QueueUrl --output text)
echo "Step 3: Sending a message"
aws sqs send-message --queue-url "$QU" --message-body "Test message" > /dev/null
echo "Step 4: Receiving without deleting (simulating failure)"
for i in 1 2 3; do aws sqs receive-message --queue-url "$QU" --visibility-timeout 0 --max-number-of-messages 1 > /dev/null 2>&1; done
sleep 2
echo "Step 5: Checking DLQ"
echo "  Main queue: $(aws sqs get-queue-attributes --queue-url "$QU" --attribute-names ApproximateNumberOfMessages --query Attributes.ApproximateNumberOfMessages --output text) messages"
echo "  DLQ: $(aws sqs get-queue-attributes --queue-url "$DU" --attribute-names ApproximateNumberOfMessages --query Attributes.ApproximateNumberOfMessages --output text) messages"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r C; [[ "$C" =~ ^[Yy]$ ]] && cleanup
