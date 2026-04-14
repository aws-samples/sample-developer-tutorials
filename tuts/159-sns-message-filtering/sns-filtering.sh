#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/sns-filter.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-$(aws configure get region 2>/dev/null)}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(openssl rand -hex 4); TOPIC="tut-filter-${RANDOM_ID}"; Q1="tut-orders-${RANDOM_ID}"; Q2="tut-alerts-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; [ -n "$SUB1_ARN" ] && aws sns unsubscribe --subscription-arn "$SUB1_ARN" 2>/dev/null; [ -n "$SUB2_ARN" ] && aws sns unsubscribe --subscription-arn "$SUB2_ARN" 2>/dev/null; aws sns delete-topic --topic-arn "$TOPIC_ARN" 2>/dev/null && echo "  Deleted topic"; [ -n "$Q1_URL" ] && aws sqs delete-queue --queue-url "$Q1_URL" 2>/dev/null; [ -n "$Q2_URL" ] && aws sqs delete-queue --queue-url "$Q2_URL" 2>/dev/null; echo "  Deleted queues"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating topic and queues"
TOPIC_ARN=$(aws sns create-topic --name "$TOPIC" --query 'TopicArn' --output text)
Q1_URL=$(aws sqs create-queue --queue-name "$Q1" --query 'QueueUrl' --output text)
Q2_URL=$(aws sqs create-queue --queue-name "$Q2" --query 'QueueUrl' --output text)
Q1_ARN=$(aws sqs get-queue-attributes --queue-url "$Q1_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
Q2_ARN=$(aws sqs get-queue-attributes --queue-url "$Q2_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)
for Q_URL in "$Q1_URL" "$Q2_URL"; do Q_ARN=$(aws sqs get-queue-attributes --queue-url "$Q_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text); aws sqs set-queue-attributes --queue-url "$Q_URL" --attributes "{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":{\\\"Service\\\":\\\"sns.amazonaws.com\\\"},\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$Q_ARN\\\"}]}\"}"; done
echo "  Topic: $TOPIC_ARN"
echo "Step 2: Subscribing with filters"
SUB1_ARN=$(aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$Q1_ARN" --attributes '{"FilterPolicy":"{\"event_type\":[\"order\"]}"}' --query 'SubscriptionArn' --output text)
SUB2_ARN=$(aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$Q2_ARN" --attributes '{"FilterPolicy":"{\"event_type\":[\"alert\"]}"}' --query 'SubscriptionArn' --output text)
echo "  Orders queue: filters for event_type=order"
echo "  Alerts queue: filters for event_type=alert"
echo "Step 3: Publishing messages"
aws sns publish --topic-arn "$TOPIC_ARN" --message "New order placed" --message-attributes '{"event_type":{"DataType":"String","StringValue":"order"}}' > /dev/null
aws sns publish --topic-arn "$TOPIC_ARN" --message "System alert" --message-attributes '{"event_type":{"DataType":"String","StringValue":"alert"}}' > /dev/null
aws sns publish --topic-arn "$TOPIC_ARN" --message "Another order" --message-attributes '{"event_type":{"DataType":"String","StringValue":"order"}}' > /dev/null
echo "  Published 3 messages (2 orders, 1 alert)"
sleep 3
echo "Step 4: Checking queues"
echo "  Orders queue: $(aws sqs get-queue-attributes --queue-url "$Q1_URL" --attribute-names ApproximateNumberOfMessages --query 'Attributes.ApproximateNumberOfMessages' --output text) messages"
echo "  Alerts queue: $(aws sqs get-queue-attributes --queue-url "$Q2_URL" --attribute-names ApproximateNumberOfMessages --query 'Attributes.ApproximateNumberOfMessages' --output text) messages"
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
