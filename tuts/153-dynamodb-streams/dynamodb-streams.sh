#!/bin/bash
WORK_DIR=$(mktemp -d); exec > >(tee -a "$WORK_DIR/ddb-streams.log") 2>&1
REGION=${AWS_DEFAULT_REGION:-${AWS_REGION:-$(aws configure get region 2>/dev/null))}; [ -z "$REGION" ] && echo "ERROR: No region" && exit 1; export AWS_DEFAULT_REGION="$REGION"; echo "Region: $REGION"
RANDOM_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1); TABLE="tut-stream-${RANDOM_ID}"
handle_error() { echo "ERROR on line $1"; trap - ERR; cleanup; exit 1; }; trap 'handle_error $LINENO' ERR
cleanup() { echo ""; echo "Cleaning up..."; aws dynamodb delete-table --table-name "$TABLE" > /dev/null 2>&1 && echo "  Deleted table"; rm -rf "$WORK_DIR"; echo "Done."; }
echo "Step 1: Creating table with streams enabled"
aws dynamodb create-table --table-name "$TABLE" --key-schema AttributeName=pk,KeyType=HASH --attribute-definitions AttributeName=pk,AttributeType=S --billing-mode PAY_PER_REQUEST --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES --query 'TableDescription.{Table:TableName,Stream:LatestStreamArn}' --output table
aws dynamodb wait table-exists --table-name "$TABLE"
STREAM_ARN=$(aws dynamodb describe-table --table-name "$TABLE" --query 'Table.LatestStreamArn' --output text)
echo "Step 2: Writing items to trigger stream events"
aws dynamodb put-item --table-name "$TABLE" --item '{"pk":{"S":"user-1"},"name":{"S":"Alice"},"age":{"N":"30"}}' 2>/dev/null
aws dynamodb put-item --table-name "$TABLE" --item '{"pk":{"S":"user-2"},"name":{"S":"Bob"},"age":{"N":"25"}}' 2>/dev/null
aws dynamodb update-item --table-name "$TABLE" --key '{"pk":{"S":"user-1"}}' --update-expression "SET age = :a" --expression-attribute-values '{":a":{"N":"31"}}' 2>/dev/null
aws dynamodb delete-item --table-name "$TABLE" --key '{"pk":{"S":"user-2"}}' 2>/dev/null
echo "  4 operations: 2 puts, 1 update, 1 delete"
echo "Step 3: Reading stream records"
SHARD_ID=$(aws dynamodbstreams describe-stream --stream-arn "$STREAM_ARN" --query 'StreamDescription.Shards[0].ShardId' --output text)
ITERATOR=$(aws dynamodbstreams get-shard-iterator --stream-arn "$STREAM_ARN" --shard-id "$SHARD_ID" --shard-iterator-type TRIM_HORIZON --query 'ShardIterator' --output text)
aws dynamodbstreams get-records --shard-iterator "$ITERATOR" --query 'Records[].{Event:eventName,Keys:dynamodb.Keys}' --output table
echo ""; echo "Tutorial complete."
echo "Do you want to clean up? (y/n): "; read -r CHOICE; [[ "$CHOICE" =~ ^[Yy]$ ]] && cleanup
